import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Ajuda', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      const Text(
        'Um passo de cada vez. Você não precisa usar tudo de uma vez.',
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comece por aqui',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Na Agenda, escolha o dia e toque em Novo evento.\n\n'
                '2. Em Hoje, escolha Pomodoro e toque em Iniciar para se concentrar.\n\n'
                '3. Ao terminar uma atividade, marque a caixinha ao lado dela.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => onNavigate(1),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Abrir agenda'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => onNavigate(0),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Começar o foco'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Como usar cada função',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      for (final topic in _topics)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ExpansionTile(
              title: Text(topic.$1),
              subtitle: Text(topic.$2),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [Text(topic.$3)],
            ),
          ),
        ),
      OutlinedButton(
        onPressed: () => onNavigate(2),
        child: const Text('Explorar métodos'),
      ),
    ],
  );

  static const _topics = [
    (
      'Hoje',
      'Veja sua rotina e inicie uma sessão de foco.',
      'Os cartões mostram o tempo planejado, os blocos concluídos e a quantidade de eventos de hoje.\n\n'
          'Use Bloco de tempo para reservar um horário. Toque na caixinha para marcar uma atividade como concluída. Os detalhes e as etapas ajudam a dividir tarefas maiores.',
    ),
    (
      'Agenda: eventos e anotações',
      'Para compromissos que têm uma data.',
      '1. Abra Agenda → Eventos e toque em um dia do calendário.\n'
          '2. Toque em Novo evento, escreva o nome e confira a data e o horário.\n'
          '3. Use Anotação para guardar local, materiais ou outros detalhes. Toque em Salvar evento.\n\n'
          'Hoje volta à data atual. Amanhã mostra o próximo dia. As setas ao lado da data avançam ou voltam um dia; as setas do calendário mudam o mês.\n\n'
          'No evento, o lápis edita, a lixeira exclui e a caixinha marca a conclusão. O lembrete depende da permissão de notificações do celular.',
    ),
    (
      'Rotina semanal e Time Blocking',
      'Para horários que se repetem na semana.',
      'Abra Agenda → Rotina semanal, escolha um dia da semana e toque em Adicionar bloco. Defina a atividade, a categoria, o início e o fim.\n\n'
          'Exemplo: aula toda segunda, das 19h às 21h. Para uma consulta em uma data específica, use Novo evento.\n\n'
          'As etapas dividem um bloco em partes menores. Reserve também horários para descanso.',
    ),
    (
      'Pomodoro e Flowtime',
      'Duas formas simples de manter o foco.',
      'Em Hoje, escolha o modo antes de iniciar.\n\n'
          'Pomodoro: trabalha com períodos definidos de foco e pausa. Toque em Iniciar; pause quando precisar. Ajuste os minutos em Preferências.\n\n'
          'Flowtime: conta o tempo de concentração sem um prazo fixo. Encerre ao chegar a uma pausa natural; o app sugere um intervalo.\n\n'
          'Reiniciar zera a sessão atual. Comece pelo Pomodoro se estiver em dúvida.',
    ),
    (
      'Três prioridades e matriz de Eisenhower',
      'Decida o que merece sua atenção.',
      'Em Métodos, edite as três prioridades para definir os resultados mais importantes do dia. Marque cada uma ao concluir.\n\n'
          'Na matriz, toque em Classificar tarefa e informe se ela é urgente e importante. O app organiza em Fazer agora, Agendar, Delegar ou Reduzir ou eliminar.\n\n'
          'A classificação orienta sua decisão: ela não cria eventos nem delega tarefas automaticamente.',
    ),
    (
      'Revisões e recuperação ativa',
      'Relembre o que estudou.',
      'Em Métodos, adicione uma revisão com assunto, data e uma pergunta para praticar.\n\n'
          'Na hora de revisar, tente responder de memória antes de consultar o material. Depois, escolha quando revisar novamente.\n\n'
          'Exemplo de pergunta: “Como explico este conceito com minhas palavras?”',
    ),
    (
      'Planejamento e plano para imprevistos',
      'Adapte sua rotina sem abandonar o plano.',
      'Em Agenda → Rotina semanal, revise os horários da semana. No cartão Plano “se… então…”, toque no lápis e escreva uma alternativa.\n\n'
          'Exemplo: “Se eu chegar tarde, estudarei por 20 minutos.” Esse texto é um lembrete pessoal; ele não altera seus eventos automaticamente.',
    ),
    (
      'Sons, temas e dados',
      'Ajuste o app ao seu jeito.',
      'Toque no ícone de ajustes no topo para abrir Preferências. Lá você escolhe Claro, Escuro ou Sistema, ajusta foco e pausa e ativa os avisos sonoros.\n\n'
          'Você pode selecionar um arquivo de áudio do celular, ouvir uma prévia ou removê-lo. O áudio escolhido toca com o app aberto; em segundo plano, o lembrete usa o som padrão do sistema.\n\n'
          'Permita notificações nas configurações do celular. A economia de bateria pode atrasar os avisos.\n\n'
          'Os dados são salvos neste aparelho. Não há sincronização com uma conta; desinstalar o app ou limpar seus dados pode apagar seus registros.',
    ),
  ];
}
