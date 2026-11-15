// Read-only Dart AST inventory. Uses the analyzer already installed with Flutter.
// Run with the Flutter tools package_config.json; see DEEP-WORKFLOW-AUDIT.md.
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

final controls = <Map<String, Object?>>[];
final routes = <Map<String, Object?>>[];
final classes = <Map<String, Object?>>[];
final inputs = <Map<String, Object?>>[];
final events = <Map<String, Object?>>[];

class Inventory extends RecursiveAstVisitor<void> {
  Inventory(this.path, this.line);
  final String path;
  final int Function(int) line;

  Map<String, Object?> location(AstNode n) {
    String owner = '', method = '';
    for (AstNode? a = n.parent; a != null; a = a.parent) {
      if (method.isEmpty && a is MethodDeclaration) method = a.name.lexeme;
      if (method.isEmpty && a is FunctionDeclaration) method = a.name.lexeme;
      if (owner.isEmpty && a is ClassDeclaration) owner = a.namePart.typeName.lexeme;
    }
    return {'source': path, 'line': line(n.offset), 'owner': owner, 'method': method};
  }

  @override
  void visitNamedArgument(NamedArgument n) {
    final name = n.name.lexeme;
    if (RegExp(r'^on[A-Z]').hasMatch(name) ||
        ['validator', 'confirmDismiss', 'onPopInvokedWithResult'].contains(name)) {
      final call = n.parent?.parent;
      final Iterable<AstNode> siblings = n.parent is ArgumentList ? (n.parent as ArgumentList).arguments : <AstNode>[];
      final labels = <String>[];
      for (final a in siblings.whereType<NamedArgument>()) {
        if (['label', 'title', 'tooltip', 'hintText', 'decoration', 'child'].contains(a.name.lexeme)) {
          labels.add('${a.name.lexeme}: ${a.argumentExpression.toSource()}');
        }
      }
      controls.add({...location(n), 'callback': name,
        'widget_or_call': call?.toSource().split('(').first ?? '',
        'labels': labels.join(' | '), 'expression': n.argumentExpression.toSource(),
        'status': 'Source inventoried; individual execution not certified'});
    }
    super.visitNamedArgument(n);
  }

  @override
  void visitClassDeclaration(ClassDeclaration n) {
    classes.add({...location(n), 'class': n.namePart.typeName.lexeme,
      'extends': n.extendsClause?.superclass.toSource() ?? '',
      'mixins': n.withClause?.toSource() ?? ''});
    super.visitClassDeclaration(n);
  }

  @override
  void visitMethodInvocation(MethodInvocation n) {
    final name = n.methodName.name;
    if (['listen', 'addListener', 'removeListener', 'addObserver', 'removeObserver',
      'setMethodCallHandler', 'addPostFrameCallback', 'periodic', 'delayed',
      'whenComplete', 'then', 'catchError', 'invokeMethod'].contains(name)) {
      events.add({...location(n), 'operation':name, 'expression':n.toSource(),
        'status':'SOURCE INVENTORIED; scheduling/cancellation/background behavior not certified'});
    }
    if (['TextField', 'TextFormField', 'CupertinoPicker', 'Slider',
      'RangeSlider', 'DropdownButton', 'RadioGroup', 'PopupMenuButton',
      'PopScope', 'AppBar', 'BackButton', 'PageView', 'showGlassSheet'].contains(name)) {
      inputs.add({...location(n), 'type': name, 'expression': n.toSource()});
    }
    if (['push', 'pushReplacement', 'pop', 'maybePop', 'popUntil',
      'showGlassSheet', 'showDialog', 'showModalBottomSheet', 'launchUrl',
      'setData', 'showNewGroupSheet', 'showLikeOptions', 'showComfortHold',
      'openPhoneDown', 'openMockPlan'].contains(name)) {
      routes.add({...location(n), 'operation': name, 'expression': n.toSource(),
        'reverse_verification': 'Not executed at every caller'});
    }
    super.visitMethodInvocation(n);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration n) {
    if (['initState', 'dispose', 'didChangeAppLifecycleState',
      'didChangeDependencies', 'didUpdateWidget'].contains(n.name.lexeme)) {
      events.add({...location(n), 'operation':n.name.lexeme, 'expression':n.toSource(),
        'status':'SOURCE INVENTORIED; lifecycle behavior not certified on hardware'});
    }
    super.visitMethodDeclaration(n);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression n) {
    final type = n.constructorName.toSource();
    if (RegExp(r'(^|\.)(TextField|TextFormField|CupertinoPicker|Slider|RangeSlider|DropdownButton|RadioGroup|PopupMenuButton|PopScope|AppBar|BackButton)(<|$)').hasMatch(type)) {
      inputs.add({...location(n), 'type': type, 'expression': n.toSource()});
    }
    super.visitInstanceCreationExpression(n);
  }
}

void main() {
  final files = Directory('lib').listSync(recursive: true).whereType<File>()
      .where((f) => f.path.endsWith('.dart')).toList()..sort((a,b)=>a.path.compareTo(b.path));
  final filesMeta = <Map<String,Object?>>[];
  for (final f in files) {
    final bytes = f.readAsBytesSync();
    final content = utf8.decode(bytes);
    final parsed = parseString(content: content, throwIfDiagnostics: false);
    final path = f.path.replaceAll('\\', '/');
    filesMeta.add({'source':path, 'lines':content.split('\n').length,
      'sha256':sha256.convert(bytes).toString(),
      'parse_errors':parsed.errors.map((e)=>e.toString()).toList()});
    parsed.unit.accept(Inventory(path, (offset)=>parsed.lineInfo.getLocation(offset).lineNumber));
  }
  final output = {'files':filesMeta,'controls':controls,'navigation':routes,'classes':classes,
    'inputs_and_back_surfaces':inputs,'events_and_lifecycle':events};
  File('docs/audit/source-inventory.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln(jsonEncode({'files':files.length,'callbacks':controls.length,'navigation':routes.length,'classes':classes.length,'inputs_and_back_surfaces':inputs.length}));
}
