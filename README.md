# Tempo Vivo

Aplicativo Flutter de agenda e gestão de tempo, com interface adaptável para celular e tablets.

## O que já funciona

- Agenda mensal interativa com seleção de data, eventos editáveis, horário, anotações, conclusão e lembrete.
- Blocos semanais recorrentes para organizar aulas, estudo, trabalho e descanso, com etapas e marcação de conclusão.
- Persistência local de eventos, blocos, prioridades, revisões, matriz, tema e preferências de som.
- Notificações locais para eventos e fim dos períodos de foco/pausa do Pomodoro, inclusive quando o sistema suspende o app (sujeitas à configuração nativa, permissões e políticas de economia de bateria do aparelho).
- Pomodoro configurável, Flowtime, três prioridades, matriz de Eisenhower, revisão espaçada com recuperação ativa e plano “se… então…”.
- Seleção, prévia e remoção de áudio para reprodução quando a sessão termina com o app aberto.
- Tema claro em cores suaves e tema escuro.

## Abrir o projeto

O projeto inclui a plataforma Android (Android 7.0/API 24 ou superior). Use Flutter, JDK 17 e Android SDK com plataforma 36 e NDK 28.2.13676358 instalados:

```sh
flutter pub get
flutter run
```

O Manifest já inclui permissões de notificação, restauração após reinício e os receptores de lembretes. O Gradle habilita desugaring e redução de código/recursos no release. O app usa agendamento não exato; o Android pode atrasar lembretes por economia de bateria. A permissão de notificações é solicitada em tempo de execução. A plataforma iOS ainda não foi gerada.

## APK Android

Para repetir a validação e gerar o APK no PowerShell:

```powershell
./tools/build_apk.ps1
# Ou informe o Flutter fora do PATH:
./tools/build_apk.ps1 -Flutter 'C:/caminho/flutter/bin/flutter.bat'
```

Se o Windows bloquear scripts locais, execute `powershell -NoProfile -ExecutionPolicy Bypass -File ./tools/build_apk.ps1` (a opção vale apenas para esse processo).

Configure `JAVA_HOME` e `ANDROID_HOME` com seus SDKs. As ferramentas preparadas nesta máquina estão em `%LOCALAPPDATA%/TempoVivoToolchain` (Java e Android SDK). O Flutter usado está em `%TEMP%/tempo-vivo-flutter-validation/flutter-stable`.

O script executa análise, testes e build release; copia o resultado para `dist/tempo-vivo.apk` e grava seu SHA-256. O APK universal atende ARM de 32/64 bits e x86_64. Não é necessário publicar em uma loja para instalar o arquivo no aparelho.

A assinatura de release usa `android/key.properties` e `android/tempo-vivo-release.jks`, gerados localmente e excluídos do Git. Faça backup privado dos dois arquivos: a mesma chave é necessária para instalar futuras atualizações sem desinstalar o app. Não compartilhe esses arquivos junto com o APK. Em outra máquina, restaure os arquivos ou configure sua própria chave com as propriedades `storeFile`, `storePassword`, `keyAlias` e `keyPassword`.

## Otimizações

A persistência captura os dados no momento da alteração, serializa gravações concorrentes e evita regravar valores idênticos, mantendo as chaves e os dados existentes. Componentes estáticos usam `const` e APIs depreciadas foram atualizadas. Os testes cobrem a ordem das gravações, remoção de preferências e recuperação após erro.
## Sobre os sons em segundo plano

O áudio escolhido pelo usuário é reproduzido ao concluir uma sessão enquanto o app está ativo. Com o app fechado/suspenso, o sistema operacional controla o som da notificação; Android e iOS não permitem que um app use diretamente qualquer música escolhida como som de notificação sem instalação/configuração nativa do áudio. A notificação agendada usa o som padrão do sistema. Um Flowtime não tem término previsto, então recebe aviso sonoro quando a pessoa encerra a sessão no app.

## Aparência

O ícone de instalação é um relógio com ponteiros azuis (`#8CB8FF`). O original vetorial está em `assets/branding/app-icon.svg`, com prévia PNG no mesmo diretório. O Android usa uma versão adaptativa a partir da API 26 e PNGs por densidade nas versões anteriores. `tools/generate_icon.ps1` regenera os PNGs a partir da mesma geometria.

Os temas Claro, Escuro e Sistema compartilham tipografia Inter local, dimensões e componentes. A paleta fica em `lib/theme/app_theme.dart`; cores de texto derivadas mantêm contraste mínimo de 4,5:1 nas superfícies verificadas. Os campos claros usam fundo branco, com foco destacado e bordas funcionais contrastantes.

Em Preferências → Aparência e foco, a escolha é aplicada imediatamente e salva no dispositivo. Sem uma escolha salva, o app acompanha o tema do sistema, inclusive mudanças enquanto está aberto. Selecionar Sistema remove a escolha explícita. Preferências antigas de tema continuam compatíveis.

A navegação adapta-se à largura disponível, mantendo os layouts vertical e horizontal. Transições de 180 ms respeitam a preferência por movimento reduzido.

Validação: 14 testes Flutter passaram (persistência, contraste, movimento reduzido, troca de tema e telas de 320 a 1440 px). A análise estática não encontrou problemas. Notificações, áudio e instalação ainda precisam de teste em aparelho Android real.

## Agenda e ajuda (1.0.1)

- Agenda em português, com atalhos Hoje e Amanhã, navegação diária e contagem de eventos do dia selecionado.
- Eventos em datas específicas e Rotina semanal separados para facilitar o planejamento.
- Criação de evento com botões separados para data e horário, orientação para nome obrigatório e confirmação ao salvar.
- Nova aba Ajuda com início rápido, atalhos e explicações sobre agenda, foco, prioridades, revisões, sons e preferências.
- Dados e chave de assinatura preservados para instalar a atualização sobre a versão anterior.

## Otimização do cronômetro (1.0.2)

As atualizações a cada segundo ficam limitadas ao painel de foco. A agenda e as estatísticas deixam de ser reconstruídas a cada tick; iniciar, pausar, reiniciar e concluir a sessão mantêm o comportamento anterior. Um teste verifica a contagem, a pausa, o reinício e a preservação dos widgets de estatísticas durante o tick.
