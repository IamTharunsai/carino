-- 0010 Vanish screenshot notice. Deploy after 0009.
-- iOS can only DETECT screenshots. The app reports one here and the server
-- posts the system notice both people see (clients can't post system
-- notices themselves since 0009). Only a participant of a Vanish chat can
-- call it, and it posts at most one notice per person per minute.
begin;

create function public.report_screenshot(p_conversation uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_mode text; v_match uuid;
begin
  select mode, match_id into v_mode, v_match from public.conversations where id = p_conversation;
  if v_match is null or not public.is_match_participant(v_match) then
    raise exception 'not your conversation';
  end if;
  if v_mode <> 'vanish' then return; end if;
  if exists (select 1 from public.messages
             where conversation_id = p_conversation and sender = auth.uid()
               and is_system_notice and created_at > now() - interval '1 minute') then
    return;
  end if;
  insert into public.messages(conversation_id, sender, kind, body, is_system_notice)
  values (p_conversation, auth.uid(), 'system',
          'A screenshot was taken in this Vanish chat.', true);
end $$;

revoke all on function public.report_screenshot(uuid) from public, anon;
grant execute on function public.report_screenshot(uuid) to authenticated;

commit;
