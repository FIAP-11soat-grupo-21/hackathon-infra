# Hackathon Infra

Este repositório orquestra a infraestrutura AWS do projeto de hackathon usando **Terragrunt** como camada de composição e módulos Terraform remotos do repositório `infra-core`.

## Visão geral

A estrutura em `src/` representa stacks de infraestrutura por domínio (rede, dados, mensageria, autenticação etc.), onde cada pasta aponta para um módulo remoto Terraform via `terraform.source`.

- Base comum em `src/terragrunt.hcl`:
  - `environment = "dev"`
  - `project.name = "hackathon"`
  - `region = "us-east-2"`
  - backend remoto em S3 (`fiap-tc-terraform-846874`)
- Todos os módulos herdam esse contexto via `include { path = find_in_parent_folders() }`
- Tags padrão (`Environment`, `ManagedBy`) e tags do AppRegistry são propagadas para praticamente todos os recursos

## O que está sendo provisionado

### 1) Identidade e catálogo da aplicação

- `src/AppRegistry/terragrunt.hcl`
  - Módulo: `APP-Registry`
  - Registra metadados da aplicação (nome e descrição) e gera tags de referência
- `src/Cognito/terragrunt.hcl`
  - Módulo: `cognito`
  - Cria User Pool/Client com:
    - verificação por e-mail
    - `generate_secret = true`
    - tokens configurados (access/id/refresh)
  - Depende de `AppRegistry` para tags

### 2) Rede e entrada de tráfego interno

- `src/Network/VPC/terragrunt.hcl`
  - Módulo: `VPC`
  - Cria VPC `10.0.0.0/16`, sub-redes privada/pública
- `src/Network/ALB/terragrunt.hcl`
  - Módulo: `ALB`
  - ALB interno com faixa de portas de app `8080-8090`
  - Depende de `VPC` e `AppRegistry`
- `src/GatewayAPI/terragrunt.hcl`
  - Módulo: `API-Gateway`
  - API Gateway (`stage v1`, auto deploy habilitado)
  - Integra com segurança/rede via SG do ALB e sub-redes privadas
  - Depende de `VPC`, `ALB` e `AppRegistry`

### 3) Execução de workloads e segredos

- `src/Secrets/GHCR/terragrunt.hcl`
  - Módulo: `SM` (Secrets Manager)
  - Cria segredo para credenciais do GHCR (`username` e `password` placeholders)
- `src/ECS/Cluster/terragrunt.hcl`
  - Módulo: `ECS-Cluster`
  - Provisiona cluster ECS em sub-redes privadas
  - Consome `VPC` + segredo GHCR

### 4) Banco de dados

- `src/RDS/terragrunt.hcl`
  - Módulo: `RDS`
  - Banco em sub-redes privadas da VPC
  - Defaults para PostgreSQL (`engine 13`, porta 5432, classe `db.t3.micro`)

### 5) Armazenamento S3

- `src/S3/Chunks/terragrunt.hcl`
  - Módulo: `S3`
  - Bucket para chunks de vídeo
  - Versionamento e criptografia habilitados
  - Publica notificações para tópico SNS `chunk-uploaded`
  - Filtro configurado para eventos de upload de `.mp4`
- `src/S3/FunctionContent/terragrunt.hcl`
  - Módulo: `S3`
  - Bucket para conteúdo de funções/lambdas
  - Versionamento e criptografia habilitados

> Observação importante: os dois módulos S3 estão marcados para gerenciamento separado (fora de `run-all`) para evitar falhas quando bucket já existir.

### 6) Barramento de eventos (SNS)

Tópicos provisionados:

- `src/SNS/chunk-uploaded/terragrunt.hcl`
- `src/SNS/chunk-processed/terragrunt.hcl`
- `src/SNS/all-chunks-processed/terragrunt.hcl`
- `src/SNS/video-processing-complete/terragrunt.hcl`
- `src/SNS/video-processed-error/terragrunt.hcl`

Todos usam módulo `SNS` e recebem tags do AppRegistry.

### 7) Filas de processamento (SQS)

Filas provisionadas:

- `src/SQS/chunk-processor/terragrunt.hcl`
  - Assina `chunk-uploaded`
  - Permite publicação do bucket de chunks (integração S3 -> SNS -> SQS)
- `src/SQS/update-video-chunk-status/terragrunt.hcl`
  - Assina `chunk-processed`
- `src/SQS/zip-processor/terragrunt.hcl`
  - Assina `all-chunks-processed`
- `src/SQS/update-video-status/terragrunt.hcl`
  - Assina `video-processing-complete` e `video-processed-error`
- `src/SQS/notificate-user/terragrunt.hcl`
  - Assina `video-processing-complete` e `video-processed-error`

Todas as filas usam configurações de retenção/visibilidade padrão semelhantes e módulo `SQS`.

## Fluxo funcional da plataforma

Em termos de negócio, a infraestrutura está organizada para um pipeline de processamento de vídeo orientado a eventos:

1. Arquivos/chunks são enviados para o bucket S3 de chunks.
2. O S3 emite evento para o tópico SNS `chunk-uploaded`.
3. A fila `chunk-processor` recebe e dispara processamento por chunk.
4. Processamentos posteriores publicam estados em tópicos como `chunk-processed` e `all-chunks-processed`.
5. Filas de atualização (`update-video-chunk-status`, `update-video-status`) recebem eventos e atualizam estado da aplicação.
6. A fila `notificate-user` recebe eventos de sucesso/erro para notificação ao usuário.

## Dependências principais entre módulos

- Quase tudo depende de `AppRegistry` para padronização de tags
- `ALB`, `RDS`, `ECS`, `GatewayAPI` dependem de `VPC`
- `GatewayAPI` depende também de `ALB`
- `ECS` depende de `Secrets/GHCR`
- `S3/Chunks` depende de `SNS/chunk-uploaded`
- `SQS/chunk-processor` depende de `S3/Chunks` e `SNS/chunk-uploaded`
- Demais filas SQS dependem dos respectivos tópicos SNS

## Como aplicar com Terragrunt

No estado atual, um fluxo seguro é:

1. Aplicar base e módulos de fundação (AppRegistry, VPC, SNS, Secrets)
2. Aplicar módulos dependentes (ALB, ECS, RDS, GatewayAPI, SQS)
3. Aplicar buckets S3 separadamente

Exemplo de execução a partir de `src/`:

```powershell
Set-Location "C:\Users\mateu\PycharmProjects\hackathon-infra\src"
terragrunt run-all plan
terragrunt run-all apply
```

Aplicação separada dos buckets S3:

```powershell
Set-Location "C:\Users\mateu\PycharmProjects\hackathon-infra\src\S3\Chunks"
terragrunt plan
terragrunt apply

Set-Location "C:\Users\mateu\PycharmProjects\hackathon-infra\src\S3\FunctionContent"
terragrunt plan
terragrunt apply
```

## Resumo executivo

Este projeto define a infraestrutura completa para um backend de processamento de vídeos na AWS, com:

- fundação de rede e segurança
- autenticação de usuários
- execução de workloads em ECS
- persistência em RDS
- pipeline assíncrono de eventos com S3 + SNS + SQS
- integração de API via API Gateway e ALB interno

Tudo é centralizado via Terragrunt, com backend remoto em S3 e organização modular por domínio para facilitar evolução e operação da stack.

