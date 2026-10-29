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

Este repositório contém o código Dart, mas ainda não tem os diretórios nativos Android/iOS de um projeto Flutter completo. Com o Flutter SDK instalado, gere os arquivos de plataforma uma vez:

```sh
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

Para notificações agendadas no Android, depois de gerar a pasta `android`, inclua em `android/app/src/main/AndroidManifest.xml` a permissão `android.permission.RECEIVE_BOOT_COMPLETED` e os receptores `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver` descritos na documentação do `flutter_local_notifications`. A versão usada também exige core library desugaring e `compileSdk` 35 ou superior. O app usa agendamento não exato para evitar pedir acesso especial a alarmes exatos; o Android pode atrasar a entrega por economia de bateria. A permissão de notificações é solicitada em tempo de execução.

## Sobre os sons em segundo plano

O áudio escolhido pelo usuário é reproduzido ao concluir uma sessão enquanto o app está ativo. Com o app fechado/suspenso, o sistema operacional controla o som da notificação; Android e iOS não permitem que um app use diretamente qualquer música escolhida como som de notificação sem instalação/configuração nativa do áudio. A notificação agendada usa o som padrão do sistema. Um Flowtime não tem término previsto, então recebe aviso sonoro quando a pessoa encerra a sessão no app.

## Aparência

Os temas Claro, Escuro e Sistema compartilham tipografia Inter local, dimensões e componentes. A paleta fica em `lib/theme/app_theme.dart`; cores de texto derivadas mantêm contraste mínimo de 4,5:1 nas superfícies verificadas. Os campos claros usam fundo branco, com foco destacado e bordas funcionais contrastantes.

Em Preferências → Aparência e foco, a escolha é aplicada imediatamente e salva no dispositivo. Sem uma escolha salva, o app acompanha o tema do sistema, inclusive mudanças enquanto está aberto. Selecionar Sistema remove a escolha explícita. Preferências antigas de tema continuam compatíveis.

A navegação adapta-se à largura disponível, mantendo os layouts vertical e horizontal. Transições de 180 ms respeitam a preferência por movimento reduzido.

Validação: nove testes Flutter passaram (contraste, movimento reduzido, troca de tema, persistência e telas de 320 a 1440 px). A análise estática não encontrou erros, mas há recomendações de estilo no código. Não foi gerado APK; notificações e áudio em aparelho real dependem da configuração nativa descrita acima.
