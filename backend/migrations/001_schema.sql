-- Belmonte Ouve IA: esquema inicial para PostgreSQL/Supabase
-- Executar SOMENTE em projeto de testes. Não ativa o frontend GitHub Pages.
create extension if not exists pgcrypto;

create table if not exists public.orgaos (
 id uuid primary key default gen_random_uuid(),
 nome text not null unique,
 email_confirmado text,
 ativo boolean not null default true,
 criado_em timestamptz not null default now()
);

create table if not exists public.manifestacoes (
 id uuid primary key default gen_random_uuid(),
 protocolo text not null unique,
 tipo text not null check(tipo in ('Reclamação','Solicitação de serviço','Denúncia','Sugestão','Elogio')),
 localidade text not null,
 descricao text,
 modalidade text not null check(modalidade in ('texto','audio')),
 anonima boolean not null default true,
 status text not null default 'recebida' check(status in ('recebida','em_analise','encaminhada','respondida','concluida')),
 destino_id uuid references public.orgaos(id),
 criada_em timestamptz not null default now(),
 atualizada_em timestamptz not null default now(),
 prazo_cidadao timestamptz,
 check (modalidade='audio' or nullif(trim(descricao),'') is not null)
);

create table if not exists public.contatos_privados (
 manifestacao_id uuid primary key references public.manifestacoes(id) on delete cascade,
 nome text,
 email text,
 telefone text,
 autorizou_notificacao boolean not null default false
);

create table if not exists public.chaves_consulta (
 manifestacao_id uuid primary key references public.manifestacoes(id) on delete cascade,
 hash_chave text not null,
 criada_em timestamptz not null default now()
);

create table if not exists public.perfis (
 usuario_id uuid primary key references auth.users(id) on delete cascade,
 papel text not null check(papel in ('ouvidoria','orgao','auditor','admin_tecnico')),
 orgao_id uuid references public.orgaos(id),
 ativo boolean not null default true
);

create table if not exists public.encaminhamentos (
 id uuid primary key default gen_random_uuid(),
 manifestacao_id uuid not null references public.manifestacoes(id) on delete cascade,
 orgao_id uuid not null references public.orgaos(id),
 prazo_interno timestamptz,
 enviado_em timestamptz,
 recebido_em timestamptz,
 criado_por uuid references auth.users(id),
 criado_em timestamptz not null default now()
);

create table if not exists public.anexos (
 id uuid primary key default gen_random_uuid(),
 manifestacao_id uuid not null references public.manifestacoes(id) on delete cascade,
 storage_key text not null unique,
 nome_original text,
 mime text not null,
 tamanho_bytes bigint not null check(tamanho_bytes between 1 and 26214400),
 tipo text not null check(tipo in ('audio','foto','documento')),
 criado_em timestamptz not null default now()
);

create table if not exists public.respostas (
 id uuid primary key default gen_random_uuid(),
 manifestacao_id uuid not null references public.manifestacoes(id) on delete cascade,
 orgao_id uuid references public.orgaos(id),
 texto text not null,
 origem_conclusao text check(origem_conclusao in ('ouvidoria','orgao')),
 justificativa text,
 criada_por uuid references auth.users(id),
 criada_em timestamptz not null default now()
);

create table if not exists public.eventos (
 id bigint generated always as identity primary key,
 manifestacao_id uuid not null references public.manifestacoes(id) on delete cascade,
 acao text not null,
 ator_id uuid references auth.users(id),
 detalhes jsonb not null default '{}'::jsonb,
 criado_em timestamptz not null default now()
);

-- Defesa em profundidade: tabelas privadas inacessíveis diretamente ao público.
alter table public.orgaos enable row level security;
alter table public.manifestacoes enable row level security;
alter table public.contatos_privados enable row level security;
alter table public.chaves_consulta enable row level security;
alter table public.perfis enable row level security;
alter table public.encaminhamentos enable row level security;
alter table public.anexos enable row level security;
alter table public.respostas enable row level security;
alter table public.eventos enable row level security;

-- Somente usuários autenticados com perfil ativo na Ouvidoria podem ler manifestações.
-- O acesso público ao protocolo/chave será mediado por endpoint seguro, NÃO por select direto.
create policy "ouvidoria leitura manifestacoes" on public.manifestacoes
for select to authenticated using (
 exists (select 1 from public.perfis p where p.usuario_id=(select auth.uid())
 and p.ativo and p.papel='ouvidoria')
);
create policy "orgao leitura encaminhadas" on public.manifestacoes
for select to authenticated using (
 exists (select 1 from public.perfis p
 join public.encaminhamentos e on e.orgao_id=p.orgao_id
 where p.usuario_id=(select auth.uid()) and p.ativo and p.papel='orgao'
 and e.manifestacao_id=manifestacoes.id)
);
create policy "ouvidoria leitura orgaos" on public.orgaos
for select to authenticated using (
 exists (select 1 from public.perfis p where p.usuario_id=(select auth.uid())
 and p.ativo and p.papel='ouvidoria')
);
-- Não criar políticas públicas de insert/update/delete nesta migração.
-- Operações de escrita exigem API no servidor com autorização, validação e auditoria.
-- Acesso a contatos, chaves, anexos e eventos: apenas por serviço confiável.
