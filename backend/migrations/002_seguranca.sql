-- Migração 002: corrigir dependências RLS e restringir acesso direto.
-- Aplicar depois de 001 em ambiente de testes.
begin;
create schema if not exists privado;
revoke all on schema privado from public;
grant usage on schema privado to authenticated;
create or replace function privado.e_ouvidoria()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.perfis p where p.usuario_id=auth.uid() and p.ativo and p.papel='ouvidoria') $$;
create or replace function privado.pode_ler_manifestacao(alvo uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.perfis p where p.usuario_id=auth.uid() and p.ativo and (p.papel='ouvidoria' or (p.papel='orgao' and exists(select 1 from public.manifestacoes m where m.id=alvo and m.destino_id=p.orgao_id and m.tipo<>'Denúncia')))) $$;
revoke all on function privado.e_ouvidoria() from public;
revoke all on function privado.pode_ler_manifestacao(uuid) from public;
grant execute on function privado.e_ouvidoria() to authenticated;
grant execute on function privado.pode_ler_manifestacao(uuid) to authenticated;
drop policy if exists "ouvidoria leitura manifestacoes" on public.manifestacoes;
drop policy if exists "orgao leitura encaminhadas" on public.manifestacoes;
drop policy if exists "ouvidoria leitura orgaos" on public.orgaos;
create policy "leitura autorizada" on public.manifestacoes for select to authenticated using (privado.pode_ler_manifestacao(id));
create policy "ouvidoria orgaos" on public.orgaos for select to authenticated using (privado.e_ouvidoria());
revoke all on public.manifestacoes,public.orgaos,public.perfis,public.contatos_privados,public.chaves_consulta,public.encaminhamentos,public.anexos,public.respostas,public.eventos from anon,authenticated;
grant select on public.manifestacoes,public.orgaos to authenticated;
-- Nenhum acesso direto a contatos, chaves, anexos ou histórico.
-- Denúncias ficam restritas à Ouvidoria até existir fluxo sigiloso específico.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('ouvidoria-privado','ouvidoria-privado',false,26214400,array['image/jpeg','image/png','image/webp','audio/webm','audio/mp4','audio/ogg','audio/mpeg','application/pdf'])
on conflict(id) do nothing;
-- Sem políticas públicas de upload/download: acesso futuro exclusivamente via API autorizada.
commit;
