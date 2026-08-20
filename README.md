# Louvor App

Aplicativo de músicas de louvor: listagem pública com busca, cadastro de
letra + cifra, tom original e tom alterado, e cultos (setlist de um dia).
Leitura é pública para qualquer pessoa com o link; edição exige login.

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
  main.dart                 # bootstrap: lê Env (--dart-define) + Supabase.initialize
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
        entities/             # Song, SongInput, SongLine (+ SongLineType)
        lyrics_parser.dart     # engine texto <-> jsonb (ver seção abaixo)
        repositories/         # SongRepository (interface)
      data/
        models/                # SongModel, SongLineModel (JSON <-> entidades)
        repositories/          # SongRepositoryImpl (Supabase)
      presentation/
        providers/             # lista, busca, detalhe, mutações (CRUD)
        pages/                  # SongsListPage, SongDetailPage, SongFormPage
        widgets/                # SongCard, AuthorsInput, MusicalKeyDropdown,
                                 # SongLinesView, LyricsPreview, SongDetailContent
    cultos/
      domain/
        entities/             # Culto, CultoInput
        repositories/         # CultoRepository (interface)
      data/
        models/                # CultoModel (JSON <-> entidade)
        repositories/          # CultoRepositoryImpl (Supabase)
      presentation/
        providers/             # lista, busca, detalhe, setlist resolvida, CRUD
        pages/                  # CultosListPage, CultoDetailPage, CultoFormPage
        widgets/                # CultoCard, CultoSongPicker
supabase/
  schema.sql                 # script único para criar tabela + RLS + realtime
```

Cada feature segue `domain -> data -> presentation`. `domain` não sabe que o
Supabase existe (só interfaces); `data` implementa contra o Supabase;
`presentation` só conhece as interfaces/providers, nunca o SDK diretamente.

## Formato da letra/cifra

No formulário de música, a pessoa cola/digita um texto único, uma linha por
vez, usando marcadores simples. O `LyricsParser`
(`lib/features/songs/domain/lyrics_parser.dart`) converte isso em uma lista
de objetos `{type, content}` — é esse array que vira o jsonb salvo na coluna
`songs.lyrics`. O formulário mostra uma pré-visualização ao vivo já com o
estilo de cada tipo.

| Marcador                    | Type      | Exemplo de entrada              | Estilo na tela              |
|------------------------------|-----------|----------------------------------|------------------------------|
| `> texto`                    | `sessao`  | `> Refrão`                       | título / negrito             |
| `\|\| texto \|\|`            | `cifra`   | `\|\| C  Am  F  G \|\|` ou `\|\| 1 6 4 5 \|\|` | cor do tema (primary) |
| `_"texto"_`                  | `letra`   | `_"Eu sei que tu és bom"_`       | itálico                      |
| qualquer outra coisa         | `extras`  | `(repete 2x)`                    | cinza                        |

Linhas em branco viram espaçamento (uma entrada `extras` vazia), preservando
a formatação original da cifra. Ao editar uma música existente, o formulário
reconstrói o texto marcado a partir do jsonb salvo (`LyricsParser.toRawText`),
então a pessoa continua editando o texto puro, não o JSON.

## Configurando o Supabase

1. Crie um projeto em https://supabase.com.
2. Abra o **SQL Editor** do projeto e rode o conteúdo de
   [`supabase/schema.sql`](supabase/schema.sql). Isso cria:
   - a tabela `songs` (título, autores, tom original, tom alterado, e
     `lyrics` como `jsonb` — ver "Formato da letra/cifra" acima);
   - a tabela `cultos` (nome, data e `song_ids` — lista ordenada de músicas
     do culto);
   - índices para busca por título/autor/conteúdo/data;
   - Row Level Security: **leitura pública**, **escrita só autenticado**;
   - as tabelas habilitadas no Realtime (as listagens atualizam sozinhas
     quando alguém edita/cadastra).

   O script é seguro para rodar mais de uma vez: se a tabela já existir com a
   coluna `lyrics` antiga (`text`), ele migra automaticamente para `jsonb`,
   preservando o texto antigo como uma linha `extras`. Eu não tenho como
   rodar esse script por vocês a partir daqui — só recebi a *anon key*, que
   não tem permissão para alterar o schema (só a senha do Postgres/service
   role teria, e não é algo que peço para vocês compartilharem). Basta
   colar o arquivo no SQL Editor e rodar.
3. Em **Project Settings -> API**, copie a **Project URL** e a
   **anon/public key** (ou "publishable key", dependendo da nomenclatura do
   seu projeto).
4. Crie os usuários que poderão editar em **Authentication -> Users -> Add
   user** (e-mail + senha). Não existe cadastro público pelo app — login é
   feito pelo menu ☰ (drawer), mas contas só são criadas manualmente por
   você no painel do Supabase.

## Configuração (SUPABASE_URL / SUPABASE_ANON_KEY)

As credenciais **não** ficam num arquivo empacotado dentro do app — elas são
passadas em tempo de build via `--dart-define`. Isso evita um problema comum
em deploys (Vercel, Netlify, GitHub Actions, ...): um arquivo `.env`
versionado seria um risco de segurança, mas um arquivo `.env` *gitignorado*
simplesmente não existe no ambiente de build do serviço, e se ele estiver
declarado como asset do Flutter, `flutter build web` falha tentando
empacotar um arquivo inexistente. Com `--dart-define` isso não acontece: se
as variáveis não forem passadas, `Env.isSupabaseConfigured` fica `false` e o
app sobe na tela de "não configurado" — o build nunca quebra por causa disso.

**Localmente:**

1. Copie `.env.json.example` para `.env.json` (gitignorado) e preencha:
   ```json
   {
     "SUPABASE_URL": "https://seu-projeto.supabase.co",
     "SUPABASE_ANON_KEY": "sua-chave-anon-publica"
   }
   ```
2. Rode/builde sempre passando `--dart-define-from-file=.env.json`:
   ```bash
   flutter pub get
   flutter run -d chrome --dart-define-from-file=.env.json
   flutter build web --release --dart-define-from-file=.env.json
   ```

## Deploy no Vercel

O Vercel não tem Flutter pré-instalado, então o Flutter SDK precisa ser
baixado como parte do build. Em **Project Settings -> Build & Development
Settings**, use:

- **Framework Preset**: `Other`
- **Install Command**:
  ```bash
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 && flutter/bin/flutter pub get
  ```
- **Build Command** (lê as env vars do próprio Vercel — nada de arquivo
  `.env` aqui):
  ```bash
  flutter/bin/flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
  ```
- **Output Directory**: `build/web`

E em **Project Settings -> Environment Variables**, cadastre `SUPABASE_URL`
e `SUPABASE_ANON_KEY` com os mesmos valores do seu `.env.json` local (para
Production/Preview/Development, como preferir). O Vercel injeta essas
variáveis como variáveis de ambiente do shell durante o build, que é o que o
`$SUPABASE_URL`/`$SUPABASE_ANON_KEY` do Build Command acima lê.

Se o build falhar com algo como `Command "flutter/bin/flutter build web
--release" exited with 1`, role o log para cima até achar o erro real (esse
texto é só o resumo final) — na maioria das vezes é uma das duas variáveis
de ambiente faltando no passo acima, ou a versão `stable` do Flutter
baixada no momento do build sendo mais antiga que a exigida por alguma
dependência (rode `flutter --version` localmente e compare).

## Build para web (outros serviços)

```bash
flutter build web --release --dart-define-from-file=.env.json
```

Isso gera `build/web`, uma pasta estática que pode ser hospedada em qualquer
serviço (Firebase Hosting, Netlify, GitHub Pages, Cloudflare Pages, etc.).
Exemplo rápido com Firebase Hosting:

```bash
npm install -g firebase-tools
firebase login
firebase init hosting   # aponte o "public directory" para build/web
firebase deploy
```

## Próximos passos sugeridos

- Gravação/reprodução do tom da música (mencionado como etapa futura).
- Testes automatizados (widget tests para os componentes de `core/widgets`,
  testes de unidade para os repositórios com um `SupabaseClient` fake).
- Paginação/lazy loading se a lista de músicas crescer muito.
