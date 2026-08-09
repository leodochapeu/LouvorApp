# Louvor App

Aplicativo de músicas de louvor: listagem pública com busca, cadastro de
letra + cifra, tom original e tom alterado. Leitura é pública para qualquer
pessoa com o link; edição exige login.

## Stack

- **Flutter** (Web como alvo principal, mas o projeto também builda para
  Android/iOS)
- **Riverpod** (`flutter_riverpod`) para gerenciamento de estado — providers
  escritos à mão (sem code generation, veja nota abaixo)
- **go_router** para navegação declarativa e guarda de rotas autenticadas
- **Supabase** (Postgres + Auth + Realtime) como backend
- Arquitetura **feature-first**

> **Nota sobre code generation:** o plano original usava `riverpod_generator`
> + `freezed`, mas o SDK do Dart disponível neste ambiente (3.11) é
> incompatível com as versões atuais desses geradores (exigem Dart ^3.12).
> Para não travar o projeto em um `build_runner` quebrado, os providers e
> entidades foram escritos manualmente — é um padrão igualmente aceito em
> produção e evita esse acoplamento de versões. Se no futuro você atualizar o
> Flutter (`flutter upgrade`) para uma versão com Dart 3.12+, dá para migrar.

## Estrutura de pastas (feature-first)

```
lib/
  app.dart                  # MaterialApp.router + tema
  main.dart                 # bootstrap: dotenv + Supabase.initialize
  core/                     # tudo que não pertence a uma feature específica
    config/                 # Env, cliente Supabase, tela de "não configurado"
    theme/                  # cores, tipografia, ThemeData
    router/                 # go_router + rotas + guarda de autenticação
    constants/              # tons musicais, tamanhos/espaçamentos
    utils/                  # validators, etc.
    widgets/                # componentes reutilizáveis (botões, inputs,
                             # cards, chips, loading/erro/empty state, drawer)
  features/
    auth/
      domain/                # AuthRepository (interface)
      data/                  # AuthRepositoryImpl (Supabase)
      presentation/
        providers/           # authControllerProvider, currentUserProvider...
        pages/                # LoginPage
        widgets/              # LoginForm
    songs/
      domain/
        entities/             # Song, SongInput
        repositories/         # SongRepository (interface)
      data/
        models/                # SongModel (mapeamento JSON <-> Song)
        repositories/          # SongRepositoryImpl (Supabase)
      presentation/
        providers/             # lista, busca, detalhe, mutações (CRUD)
        pages/                  # SongsListPage, SongDetailPage, SongFormPage
        widgets/                # SongCard, AuthorsInput, MusicalKeyDropdown...
supabase/
  schema.sql                 # script único para criar tabela + RLS + realtime
```

Cada feature segue `domain -> data -> presentation`. `domain` não sabe que o
Supabase existe (só interfaces); `data` implementa contra o Supabase;
`presentation` só conhece as interfaces/providers, nunca o SDK diretamente.

## Configurando o Supabase

1. Crie um projeto em https://supabase.com.
2. Abra o **SQL Editor** do projeto e rode o conteúdo de
   [`supabase/schema.sql`](supabase/schema.sql) uma única vez. Isso cria:
   - a tabela `songs` (título, autores, tom original, tom alterado, letra);
   - índices para busca por título/autor;
   - Row Level Security: **leitura pública**, **escrita só autenticado**;
   - a tabela habilitada no Realtime (a listagem atualiza sozinha quando
     alguém edita/cadastra).
3. Em **Project Settings -> API**, copie a **Project URL** e a
   **anon/public key** (ou "publishable key", dependendo da nomenclatura do
   seu projeto).
4. Copie `.env.example` para `.env` e preencha:
   ```
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_ANON_KEY=sua-chave-anon-publica
   ```
5. Crie os usuários que poderão editar em **Authentication -> Users -> Add
   user** (e-mail + senha). Não existe cadastro público pelo app — login é
   feito pelo menu ☰ (drawer), mas contas só são criadas manualmente por
   você no painel do Supabase.

Enquanto o `.env` não estiver preenchido, o app sobe numa tela avisando que
falta configurar, em vez de quebrar.

## Rodando localmente

```bash
flutter pub get
flutter run -d chrome
```

## Build para web / deploy

```bash
flutter build web
```

Isso gera `build/web`, uma pasta estática que pode ser hospedada em qualquer
serviço (Firebase Hosting, Netlify, Vercel, GitHub Pages, Cloudflare Pages,
etc.). Exemplo rápido com Firebase Hosting:

```bash
npm install -g firebase-tools
firebase login
firebase init hosting   # aponte o "public directory" para build/web
firebase deploy
```

Lembre-se de configurar as variáveis do `.env` também no seu pipeline de
build (ou gerar o `.env` de produção antes de rodar `flutter build web`),
já que o arquivo não é versionado.

## Próximos passos sugeridos

- Gravação/reprodução do tom da música (mencionado como etapa futura).
- Testes automatizados (widget tests para os componentes de `core/widgets`,
  testes de unidade para os repositórios com um `SupabaseClient` fake).
- Paginação/lazy loading se a lista de músicas crescer muito.
