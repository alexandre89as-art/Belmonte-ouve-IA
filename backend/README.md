# Backend — Belmonte Ouve IA (fase de preparação)

**Status:** esquema inicial criado no repositório. **Não implantado, não conectado ao site, não homologado para dados reais.**

## O que foi entregue
- Migração SQL inicial em `migrations/001_schema.sql`.
- Tabelas para manifestações, contatos separados, chaves de consulta, órgãos, perfis, encaminhamentos, anexos, respostas e eventos.
- Row Level Security ativada em todas as tabelas; nenhuma escrita pública liberada.
- Leitura de manifestações por perfil da Ouvidoria e leitura limitada para órgãos encaminhados.

## O que falta antes da operação
1. Provisionar projeto Supabase/PostgreSQL de testes, com responsável autorizado e credenciais guardadas fora do GitHub.
2. Revisar SQL e modelo de ameaça; implementar serviço de API com validação, geração atômica de protocolos, hash das chaves, rate limiting, auditoria e transações.
3. Implementar autenticação multifator e administração de perfis; revisar políticas de acesso a cada tabela e aos anexos.
4. Criar bucket privado, políticas de download e upload, análise de arquivos e limites de tamanho; nunca expor arquivos sigilosos em URLs públicas.
5. Implementar notificações de e-mail e remessas apenas para destinatários confirmados oficialmente.
6. Testar com dados fictícios em dispositivos distintos; verificar isolamento entre secretarias, denúncias sigilosas e consulta por protocolo + chave.
7. Formalizar LGPD, retenção, prazos legais e homologação institucional antes de aceitar manifestações reais.

**Atenção:** GitHub Pages é estático. O código SQL não cria banco automaticamente. Não inserir service-role key ou senhas no HTML. O armazenamento atual no navegador permanece independente desta estrutura.

## Modelo de atendimento
O cidadão poderá enviar texto ou áudio; a API deverá gravar primeiro o arquivo no armazenamento privado, registrar a manifestação em transação e retornar protocolo + chave. Se o upload falhar, não afirmar que o áudio foi recebido. Ouvidoria poderá visualizar a manifestação em outro dispositivo apenas depois de backend e login funcionando.
