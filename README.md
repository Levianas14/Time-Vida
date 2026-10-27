# Tempo Vivo

Aplicativo Flutter para planejamento de rotina, divisão de atividades e métodos de estudo e gestão do tempo.

## Métodos implementados

- **Time Blocking:** agenda semanal por dia, blocos com duração, categoria e etapas.
- **Repetição espaçada e recuperação ativa:** cadastro de assuntos, data de revisão, pergunta de evocação, resposta sem consulta e reagendamento em intervalos escolhidos.
- **Pomodoro e Flowtime:** ciclos configuráveis de foco e pausa, ou sessão livre até um ponto natural de descanso.
- **Três prioridades:** lista diária editável e marcável.
- **Matriz de Eisenhower:** classificação de tarefas por urgência e importância nos quatro quadrantes.
- **Planejamento semanal:** navegação pelos dias e plano editável “se… então…” para imprevistos.
- **Temas:** aparência clara em tons suaves e aparência escura, selecionáveis nas preferências.
- **Som de término:** seleção de arquivo de áudio do aparelho, cópia para armazenamento privado do app e prévia de reprodução.

## Como abrir

1. Instale o Flutter SDK e um editor compatível, como Android Studio ou VS Code.
2. Na pasta do projeto, execute `flutter pub get`.
3. Execute `flutter run` com um emulador ou aparelho conectado.

Nas preferências, em **Som de término**, toque no ícone de pasta para escolher um arquivo de áudio suportado pelo aparelho. Use **Testar som** para ouvir a prévia. O app guarda uma cópia na área privada do aplicativo e usa esse som ao terminar o Pomodoro ou encerrar uma sessão Flowtime. A reprodução durante o app fechado ainda requer configurar notificações e serviço de áudio em segundo plano.

O layout reorganiza agenda, matriz e painel de foco conforme a largura disponível e acompanha a rotação do aparelho. As atividades e preferências ainda não são persistidas entre execuções; alarmes em segundo plano também exigem integração de notificações. O ambiente desta edição não tem Flutter/Dart disponível, então a compilação não pôde ser validada aqui.
