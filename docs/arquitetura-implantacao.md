# Belmonte Ouve IA — Arquitetura para implantação segura

Status: especificação técnica; **não implementada** no GitHub Pages. O site atual é somente uma demonstração pública com localStorage.

## Objetivo
Permitir que cidadãos registrem manifestações e acompanhem respostas, enquanto Ouvidoria e órgãos municipais trabalham em dispositivos distintos, com controle de acesso e rastreabilidade.

## Componentes
- Front-end público: formulário, acompanhamento por protocolo + chave forte e acessibilidade.
- API autenticada: validação de dados, rate limiting, geração de protocolo no servidor, tramitação e histórico imutável.
- Banco PostgreSQL gerenciado com políticas de acesso por perfil e segregação dos dados identificadores.
- Armazenamento privado de anexos: criptografia, antivírus, tamanho/MIME verificados, URLs temporárias e auditoria de downloads.
- Serviço de notificações: fila de e-mails com provedor transacional, reenvio, confirmação técnica de entrega e registro do status. Nunca colocar dados sigilosos em e-mails sem autorização e base legal.
- Processamento de áudio/transcrição: consentimento e regras de retenção, revisão do cidadão, proteção contratual do fornecedor.

## Perfis e permissões
1. Cidadão: registrar e consultar somente seu protocolo com chave segura; pode optar por anonimato.
2. Ouvidoria: triagem, classificação, controle de sigilo, encaminhamento, prazos, resposta e encerramento.
3. Secretaria/órgão: acesso somente às manifestações encaminhadas ao próprio órgão, sem dados de identidade protegidos.
4. Administrador técnico: gestão de usuários e configurações; não deve ter acesso automático ao teor de denúncias.
5. Auditor autorizado: acesso de leitura às trilhas conforme competência.

## Entidades
- manifestacoes(id UUID, protocolo UNIQUE, tipo, localidade, relato, status, criada_em, atualizada_em, sigilo, prazo_resposta_cidadao)
- contatos_privados(manifestacao_id, nome, email, telefone, consentimento_notificacao) — acesso restrito à Ouvidoria
- chaves_consulta(manifestacao_id, hash_chave, expira_em)
- orgaos(id, nome, email_confirmado, ativo)
- encaminhamentos(id, manifestacao_id, orgao_id, enviado_em, prazo_interno, recebido_em, status)
- anexos(id, manifestacao_id, storage_key_privada, nome_original, mime, tamanho, hash, nivel_sigilo)
- respostas(id, manifestacao_id, orgao_id, texto, criada_em, publicada_ao_cidadao_em)
- eventos_auditoria(id, manifestacao_id, ator_id, acao, data_hora, metadados_minimos)
- usuarios(id, papel, orgao_id, ativo)

## Fluxo
Registro -> protocolo e chave -> triagem -> decisão sobre sigilo e anexos -> encaminhamento -> prazo -> devolutiva -> revisão pela Ouvidoria -> resposta ao cidadão -> conclusão.

Prazos legais devem ser parametrizados após validação da regulamentação municipal e da Lei 13.460/2017. Prazo interno de secretaria é distinto do prazo de resposta ao cidadão.

## Regras de segurança e LGPD
- Não publicar chaves de API, senhas, banco de dados ou tokens no HTML/JavaScript do GitHub Pages.
- Não armazenar dados pessoais reais no localStorage.
- Não usar GitHub Pages como backend de manifestações reais.
- Autenticação multifator para servidores; logs de auditoria e backups testados.
- Denúncias anônimas não têm retorno individual, mas podem ser acompanhadas por protocolo e chave.
- Identificação e contato nunca seguem automaticamente para secretarias.
- Definir controlador, operador, encarregado, política de privacidade, base legal, retenção e resposta a incidentes antes do lançamento.
- E-mail de órgão deve ser confirmado oficialmente antes de ativar remessas.
- Exportação JSON atual é apenas de registros fictícios, não representa sincronização entre dispositivos.

## Implantação — pré-requisitos
1. Escolher infraestrutura/backend e custodiante institucional dos dados.
2. Obter credenciais administrativas e configuração de domínio, e-mails e banco em ambiente seguro.
3. Implementar migrações, RLS/permissões, API, testes de autorização e armazenamento privado.
4. Integrar front-end à API; executar testes de segurança e acessibilidade.
5. Homologação municipal, regulamento de prazos e capacitação.
6. Somente após homologação, habilitar recepção de manifestações reais.

## Aceite mínimo
- Um registro criado em dispositivo A aparece na Ouvidoria autenticada em B.
- Órgão X não acessa registros de Y.
- Identidade de denunciante protegida não é exibida a órgão destinatário.
- Anexo acessível apenas com permissão e por prazo limitado.
- Remessa registra destinatário, anexos autorizados, prazo e resultado do envio.
- Histórico registra autoria e momento de cada alteração sem edição retroativa.
- Cidadão consulta com protocolo + chave; não pode enumerar protocolos de terceiros.
