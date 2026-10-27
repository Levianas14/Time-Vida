import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final notifications = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  try {
    final deviceZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceZone.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
  }
  await notifications.initialize(settings: const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(requestAlertPermission: true, requestSoundPermission: true),
  ));
  runApp(const TempoVivoApp());
}

Future<void> scheduleReminder({required int id, required String title, required String body, required DateTime when}) async {
  if (when.isBefore(DateTime.now())) return;
  await notifications.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(when, tz.local),
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails('tempo_vivo_events', 'Agenda e alarmes', channelDescription: 'Lembretes de eventos e sessões', importance: Importance.max, priority: Priority.high),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

class TempoVivoAppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF648B78), onPrimary: Colors.white,
          secondary: Color(0xFF9CB7A6), surface: Color(0xFFFFFEFC),
          onSurface: Color(0xFF34413A), error: Color(0xFFB96F6F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F5),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF7F8F5), surfaceTintColor: Colors.transparent),
        navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFFFBFCF9), indicatorColor: Color(0xFFDCE9DF)),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        cardTheme: CardThemeData(color: const Color(0xFFFFFEFC), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB5D0BE), onPrimary: Color(0xFF26382D),
          secondary: Color(0xFFAFC7D0), surface: Color(0xFF202A25),
          onSurface: Color(0xFFE3E9E3), error: Color(0xFFE2A4A0),
        ),
        scaffoldBackgroundColor: const Color(0xFF171E1A),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF171E1A), surfaceTintColor: Colors.transparent),
        navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF202A25), indicatorColor: Color(0xFF35483C)),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        cardTheme: CardThemeData(color: const Color(0xFF202A25), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      );
}

class TempoVivoApp extends StatelessWidget {
  const TempoVivoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Tempo Vivo',
        debugShowCheckedModeBanner: false,
        theme: TempoVivoAppTheme.light,
        darkTheme: TempoVivoAppTheme.dark,
        home: const HomeScreen(),
      );
}

class Activity {
  Activity({
    required this.title,
    required this.category,
    required this.start,
    required this.end,
    required this.color,
    this.done = false,
    this.steps = const [],
    this.weekday,
    this.review,
  });

  final String title;
  final String category;
  final TimeOfDay start;
  final TimeOfDay end;
  final Color color;
  bool done;
  final List<String> steps;
  final int? weekday;
  final ReviewPlan? review;
  int get minutes => end.hour * 60 + end.minute - start.hour * 60 - start.minute;
}

class ReviewPlan {
  ReviewPlan({required this.topic, required this.due, this.prompt = ''});
  final String topic;
  DateTime due;
  String prompt;
  bool done = false;
}

class StudyPriority {
  StudyPriority(this.title);
  String title;
  bool done = false;
}

class EisenhowerTask {
  EisenhowerTask(this.title, this.urgent, this.important);
  String title;
  bool urgent;
  bool important;
}

class CalendarEvent {
  CalendarEvent({required this.id, required this.title, required this.startsAt, this.note = '', this.done = false, this.reminder = true});
  final int id;
  String title;
  DateTime startsAt;
  String note;
  bool done;
  bool reminder;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final List<CalendarEvent> _events = [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _loaded = false;
  DateTime? _focusEndAt;
  final List<Activity> _activities = [
    Activity(title: 'Acordar e se preparar', category: 'Rotina', start: const TimeOfDay(hour: 7, minute: 0), end: const TimeOfDay(hour: 7, minute: 40), color: const Color(0xFFE9A66B), done: true, weekday: DateTime.monday),
    Activity(title: 'Aula de matemática', category: 'Aula', start: const TimeOfDay(hour: 8, minute: 0), end: const TimeOfDay(hour: 9, minute: 30), color: const Color(0xFF7895C8), weekday: DateTime.monday),
    Activity(title: 'Revisar conteúdo da aula', category: 'Estudo', start: const TimeOfDay(hour: 10, minute: 0), end: const TimeOfDay(hour: 10, minute: 50), color: const Color(0xFF68A88B), weekday: DateTime.monday, steps: ['Recuperar ideias sem consultar · 15 min', 'Resolver exercícios · 25 min', 'Conferir e anotar dúvidas · 10 min']),
    Activity(title: 'Pausa para almoço', category: 'Pausa', start: const TimeOfDay(hour: 12, minute: 0), end: const TimeOfDay(hour: 13, minute: 0), color: const Color(0xFFE9A66B), weekday: DateTime.monday),
    Activity(title: 'Trabalho de história', category: 'Estudo', start: const TimeOfDay(hour: 14, minute: 0), end: const TimeOfDay(hour: 15, minute: 30), color: const Color(0xFF68A88B), weekday: DateTime.monday, steps: ['Pesquisar fontes · 25 min', 'Escrever primeira parte · 40 min', 'Revisar · 25 min']),
    Activity(title: 'Tempo livre', category: 'Pessoal', start: const TimeOfDay(hour: 17, minute: 0), end: const TimeOfDay(hour: 18, minute: 0), color: const Color(0xFFB08BC3), weekday: DateTime.monday),
  ];

  final List<StudyPriority> _priorities = [StudyPriority('Revisar o conteúdo da aula'), StudyPriority('Avançar no trabalho de história'), StudyPriority('Organizar materiais de amanhã')];
  final List<EisenhowerTask> _eisenhower = [
    EisenhowerTask('Entregar trabalho de história', true, true),
    EisenhowerTask('Estudar para a prova da semana', false, true),
    EisenhowerTask('Responder mensagens não urgentes', false, false),
  ];
  final List<ReviewPlan> _reviews = [
    ReviewPlan(topic: 'Equações do 2º grau', due: DateTime.now(), prompt: 'Quais são os passos para encontrar as raízes?'),
    ReviewPlan(topic: 'Vocabulário de inglês — unidade 4', due: DateTime.now().add(const Duration(days: 1)), prompt: 'Escreva de memória cinco palavras novas e seus significados.'),
  ];

  int _tab = 0;
  int _focusMinutes = 25;
  int _breakMinutes = 5;
  int _remaining = 25 * 60;
  int _flowElapsed = 0;
  int _flowBreak = 5;
  int _weeklyDay = DateTime.monday;
  bool _running = false;
  bool _isBreak = false;
  bool _flowMode = false;
  bool _flowPaused = false;
  bool _flowSoundPlayed = false;
  bool _soundEnabled = true;
  bool _darkMode = false;
  String _soundName = 'Som suave';
  String? _soundPath;
  String? _savedSoundPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _ifThen = 'Se eu chegar tarde, farei 20 minutos de revisão em vez de cancelar o estudo.';
  Timer? _timer;
  final _timerWatch = Stopwatch();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timerWatch.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedData();
    _requestNotificationPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _running && !_flowMode && _focusEndAt != null) {
      final seconds = _focusEndAt!.difference(DateTime.now()).inSeconds;
      if (seconds <= 0) {
        _timer?.cancel();
        setState(() { _remaining = 0; _running = false; });
        _finishPomodoro();
      } else {
        setState(() => _remaining = seconds);
        _startTicker();
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    await notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final rawEvents = prefs.getString('tempo_vivo_events_v1');
      if (rawEvents != null) _events.addAll((jsonDecode(rawEvents) as List<dynamic>).map((item) { final map = item as Map<String, dynamic>; return CalendarEvent(id: map['id'] as int, title: map['title'] as String, startsAt: DateTime.parse(map['startsAt'] as String), note: map['note'] as String? ?? '', done: map['done'] as bool? ?? false, reminder: map['reminder'] as bool? ?? true); }));
      final rawActivities = prefs.getString('tempo_vivo_activities_v1');
      if (rawActivities != null) { _activities.clear(); _activities.addAll((jsonDecode(rawActivities) as List<dynamic>).map((item) { final map = item as Map<String, dynamic>; return Activity(title: map['title'] as String, category: map['category'] as String, start: TimeOfDay(hour: map['sh'] as int, minute: map['sm'] as int), end: TimeOfDay(hour: map['eh'] as int, minute: map['em'] as int), color: Color(map['color'] as int), done: map['done'] as bool? ?? false, weekday: map['weekday'] as int?, steps: (map['steps'] as List<dynamic>).cast<String>()); })); }
      final rawReviews = prefs.getString('tempo_vivo_reviews_v1');
      if (rawReviews != null) { _reviews.clear(); _reviews.addAll((jsonDecode(rawReviews) as List<dynamic>).map((item) { final map = item as Map<String, dynamic>; return ReviewPlan(topic: map['topic'] as String, due: DateTime.parse(map['due'] as String), prompt: map['prompt'] as String)..done = map['done'] as bool? ?? false; })); }
      final rawPriorities = prefs.getString('tempo_vivo_priorities_v1');
      if (rawPriorities != null) { _priorities.clear(); _priorities.addAll((jsonDecode(rawPriorities) as List<dynamic>).map((item) { final map = item as Map<String, dynamic>; return StudyPriority(map['title'] as String)..done = map['done'] as bool? ?? false; })); }
      final rawMatrix = prefs.getString('tempo_vivo_matrix_v1');
      if (rawMatrix != null) { _eisenhower.clear(); _eisenhower.addAll((jsonDecode(rawMatrix) as List<dynamic>).map((item) { final map = item as Map<String, dynamic>; return EisenhowerTask(map['title'] as String, map['urgent'] as bool, map['important'] as bool); })); }
      _darkMode = prefs.getBool('tempo_vivo_dark') ?? false;
      _soundEnabled = prefs.getBool('tempo_vivo_sound_enabled') ?? true;
      _soundName = prefs.getString('tempo_vivo_sound_name') ?? 'Som suave';
      _focusMinutes = prefs.getInt('tempo_vivo_focus_minutes') ?? 25;
      _breakMinutes = prefs.getInt('tempo_vivo_break_minutes') ?? 5;
      _ifThen = prefs.getString('tempo_vivo_if_then') ?? _ifThen;
      final savedAudio = prefs.getString('tempo_vivo_sound_path');
      if (savedAudio != null && await File(savedAudio).exists()) { _soundPath = savedAudio; _savedSoundPath = savedAudio; }
    } catch (_) { /* An invalid save does not prevent using the agenda. */ }
    if (mounted) {
      setState(() => _loaded = true);
      for (final event in _events.where((event) => event.reminder && !event.done)) {
        scheduleReminder(id: event.id, title: event.title, body: event.note.isEmpty ? 'Seu evento está começando.' : event.note, when: event.startsAt);
      }
    }
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tempo_vivo_events_v1', jsonEncode(_events.map((event) => {'id': event.id, 'title': event.title, 'startsAt': event.startsAt.toIso8601String(), 'note': event.note, 'done': event.done, 'reminder': event.reminder}).toList()));
    await prefs.setString('tempo_vivo_activities_v1', jsonEncode(_activities.map((a) => {'title': a.title, 'category': a.category, 'sh': a.start.hour, 'sm': a.start.minute, 'eh': a.end.hour, 'em': a.end.minute, 'color': a.color.value, 'done': a.done, 'weekday': a.weekday, 'steps': a.steps}).toList()));
    await prefs.setString('tempo_vivo_reviews_v1', jsonEncode(_reviews.map((r) => {'topic': r.topic, 'due': r.due.toIso8601String(), 'prompt': r.prompt, 'done': r.done}).toList()));
    await prefs.setString('tempo_vivo_priorities_v1', jsonEncode(_priorities.map((p) => {'title': p.title, 'done': p.done}).toList()));
    await prefs.setString('tempo_vivo_matrix_v1', jsonEncode(_eisenhower.map((task) => {'title': task.title, 'urgent': task.urgent, 'important': task.important}).toList()));
    await prefs.setBool('tempo_vivo_dark', _darkMode);
    await prefs.setBool('tempo_vivo_sound_enabled', _soundEnabled);
    await prefs.setString('tempo_vivo_sound_name', _soundName);
    await prefs.setInt('tempo_vivo_focus_minutes', _focusMinutes);
    await prefs.setInt('tempo_vivo_break_minutes', _breakMinutes);
    await prefs.setString('tempo_vivo_if_then', _ifThen);
    if (_soundPath != null) await prefs.setString('tempo_vivo_sound_path', _soundPath!); else await prefs.remove('tempo_vivo_sound_path');
  }

  String _time(TimeOfDay value) => value.format(context);
  String _clockFromSeconds(int seconds) => '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  String get _clock => _clockFromSeconds(_remaining);

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_flowMode && !_flowPaused) {
        setState(() => _flowElapsed = _timerWatch.elapsed.inSeconds);
      } else if (!_flowMode && _remaining <= 1) {
        _timer?.cancel();
        setState(() { _remaining = 0; _running = false; });
        _finishPomodoro();
      } else if (!_flowMode) {
        setState(() => _remaining--);
      }
    });
  }

  void _toggleTimer() {
    if (_flowMode) {
      if (_running) {
        _timerWatch.stop();
        setState(() { _running = false; _flowPaused = true; _flowBreak = (_flowElapsed ~/ 60 ~/ 25 * 5).clamp(3, 15).toInt(); });
        _timer?.cancel();
        if (!_flowSoundPlayed && _soundEnabled) {
          _flowSoundPlayed = true;
          _playCompletionSound();
        }
        _showFlowSummary(playSound: false);
      } else {
        _timerWatch.reset();
        setState(() { _running = true; _flowPaused = false; _flowElapsed = 0; _flowSoundPlayed = false; });
        _timerWatch.start();
        _startTicker();
      }
      return;
    }
    if (_running) {
      _timer?.cancel();
      notifications.cancel(id: -1);
      _focusEndAt = null;
      setState(() => _running = false);
    } else {
      _focusEndAt = _flowMode ? null : DateTime.now().add(Duration(seconds: _remaining));
      setState(() => _running = true);
      _schedulePomodoroAlarm();
      _startTicker();
    }
  }

  void _finishPomodoro() {
    _focusEndAt = null;
    notifications.cancel(id: -1);
    if (_soundEnabled) _playCompletionSound();
    setState(() { _isBreak = !_isBreak; _remaining = (_isBreak ? _breakMinutes : _focusMinutes) * 60; });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timerWatch.stop();
    _timerWatch.reset();
    _focusEndAt = null;
    notifications.cancel(id: -1);
        setState(() { _running = false; _flowPaused = false; _flowElapsed = 0; _flowSoundPlayed = false; _remaining = (_isBreak ? _breakMinutes : _focusMinutes) * 60; });
  }

  void _showFlowSummary({bool playSound = true}) {
    if (playSound && _soundEnabled) _playCompletionSound();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Flowtime: ${_flowElapsed ~/ 60} min de foco · pausa sugerida: $_flowBreak min')));
  }

  Future<void> _playCompletionSound() async {
    if (_soundPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sessão concluída · $_soundName')));
      return;
    }
    try {
      await _audioPlayer.setFilePath(_soundPath!);
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível reproduzir este áudio. Escolha outro arquivo.')));
    }
  }

  Future<void> _pickAlarmAudio(StateSetter updateSheet) async {
    final file = await FilePicker.pickFile(type: FileType.audio);
    if (file == null || !mounted) return;
    try {
      final source = file.path;
      if (source == null) throw StateError('Arquivo sem caminho local');
      final directory = await getApplicationDocumentsDirectory();
      final extension = file.extension == null ? '' : '.${file.extension}';
      final destination = '${directory.path}/alarm_${DateTime.now().millisecondsSinceEpoch}$extension';
      final copied = await File(source).copy(destination);
      if (!mounted) return;
      setState(() { _soundPath = copied.path; _savedSoundPath = copied.path; _soundName = file.name; });
      _saveEvents();
      updateSheet(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível guardar esse arquivo de áudio.')));
    }
  }

  Future<void> _previewAlarmAudio() async {
    if (_soundPath == null) return;
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.setFilePath(_soundPath!);
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play();
      }
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível reproduzir este áudio.')));
    }
  }

  Future<void> _addActivity({int? weekday}) async {
    final result = await showDialog<Activity>(context: context, builder: (_) => ActivityDialog(initialWeekday: weekday));
    if (result != null && mounted) {
      setState(() => _activities.add(result));
      _saveEvents();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloco de tempo adicionado.')));
    }
  }

  Future<void> _addEvent() async {
    if (!_loaded) return;
    final event = await showDialog<CalendarEvent>(context: context, builder: (_) => EventDialog(initialDate: _selectedDate));
    if (event == null || !mounted) return;
    setState(() => _events.add(event));
    await _saveEvents();
    if (event.reminder) await scheduleReminder(id: event.id, title: event.title, body: event.note.isEmpty ? 'Seu evento está começando.' : event.note, when: event.startsAt);
  }

  Future<void> _editEvent(CalendarEvent event) async {
    final updated = await showDialog<CalendarEvent>(context: context, builder: (_) => EventDialog(initialDate: _selectedDate, existing: event));
    if (updated == null || !mounted) return;
    setState(() {
      final index = _events.indexWhere((item) => item.id == event.id);
      if (index >= 0) _events[index] = updated;
    });
    await notifications.cancel(id: event.id);
    await _saveEvents();
    if (updated.reminder) await scheduleReminder(id: updated.id, title: updated.title, body: updated.note.isEmpty ? 'Seu evento está começando.' : updated.note, when: updated.startsAt);
  }

  Future<void> _toggleEvent(CalendarEvent event) async {
    setState(() => event.done = !event.done);
    if (event.done) { await notifications.cancel(id: event.id); }
    else if (event.reminder) { await scheduleReminder(id: event.id, title: event.title, body: event.note.isEmpty ? 'Seu evento está começando.' : event.note, when: event.startsAt); }
    await _saveEvents();
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    setState(() => _events.remove(event));
    await notifications.cancel(id: event.id);
    await _saveEvents();
  }

  Future<void> _schedulePomodoroAlarm() async {
    if (!_flowMode) {
      await scheduleReminder(id: -1, title: 'Tempo Vivo · ${_isBreak ? 'pausa concluída' : 'sessão concluída'}', body: _isBreak ? 'Sua pausa terminou. Quando quiser, retome o foco.' : 'Seu período de foco terminou.', when: DateTime.now().add(Duration(seconds: _remaining)));
    }
  }

  Future<void> _addReview() async {
    final result = await showDialog<ReviewPlan>(context: context, builder: (_) => const ReviewDialog());
    if (result != null && mounted) setState(() => _reviews.add(result));
    _saveEvents();
  }

  Future<String?> _askText(String title, {String initial = '', String hint = 'Digite aqui'}) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: InputDecoration(hintText: hint)),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: Text('Salvar'))],
    ));
    controller.dispose();
    return value;
  }

  Future<void> _editPriority(int index) async {
    final value = await _askText('Prioridade ${index + 1}', initial: _priorities[index].title, hint: 'O resultado mais importante');
    if (value != null && value.isNotEmpty) { setState(() => _priorities[index].title = value); _saveEvents(); }
  }

  Future<void> _addEisenhowerTask() async {
    final title = await _askText('Nova tarefa da matriz', hint: 'O que precisa ser feito?');
    if (title == null || title.isEmpty) return;
    if (!mounted) return;
    final answers = await showDialog<(bool, bool)>(context: context, builder: (dialogContext) => _EisenhowerQuestionDialog());
    if (answers != null) { setState(() => _eisenhower.add(EisenhowerTask(title, answers.$1, answers.$2))); _saveEvents(); }
  }

  Future<void> _showSettings() async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (sheetContext) => StatefulBuilder(builder: (context, updateSheet) => Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 28 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Aparência e foco', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Claro'), icon: Icon(Icons.light_mode_outlined)), ButtonSegment(value: true, label: Text('Escuro'), icon: Icon(Icons.dark_mode_outlined))], selected: {_darkMode}, onSelectionChanged: (value) { setState(() => _darkMode = value.first); _saveEvents(); updateSheet(() {}); }),
        const SizedBox(height: 12),
        Text('Sessões de foco', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('Avisos sonoros'), value: _soundEnabled, onChanged: (value) { setState(() => _soundEnabled = value); _saveEvents(); updateSheet(() {}); }),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.music_note_outlined),
          title: Text(_soundPath == null ? 'Som de término' : _soundName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_soundPath == null ? 'Toque para escolher áudio do aparelho' : 'Arquivo selecionado'),
          trailing: IconButton(tooltip: 'Escolher arquivo de áudio', onPressed: () => _pickAlarmAudio(updateSheet), icon: const Icon(Icons.folder_open_outlined)),
          onTap: () => _pickAlarmAudio(updateSheet),
        ),
        if (_soundPath != null) Row(children: [
          TextButton.icon(onPressed: _previewAlarmAudio, icon: Icon(_audioPlayer.playing ? Icons.stop : Icons.play_arrow), label: Text(_audioPlayer.playing ? 'Parar prévia' : 'Testar som')),
          const Spacer(),
          TextButton.icon(onPressed: () async { await _audioPlayer.stop(); final oldPath = _savedSoundPath; setState(() { _soundPath = null; _savedSoundPath = null; _soundName = 'Som suave'; }); if (oldPath != null) { try { await File(oldPath).delete(); } catch (_) {} } _saveEvents(); updateSheet(() {}); }, icon: const Icon(Icons.delete_outline), label: const Text('Remover')),
        ]),
        const Divider(),
        _durationSlider(context, 'Pomodoro · foco', _focusMinutes, 10, 60, (value) { setState(() { _focusMinutes = value; if (!_isBreak && !_running) _remaining = value * 60; _saveEvents(); }); updateSheet(() {}); }),
        _durationSlider(context, 'Pomodoro · pausa', _breakMinutes, 3, 20, (value) { setState(() { _breakMinutes = value; if (_isBreak && !_running) _remaining = value * 60; _saveEvents(); }); updateSheet(() {}); }),
        const SizedBox(height: 8),
        Text('O som toca quando o app está aberto. Alarmes enquanto o app está fechado precisam de notificações em segundo plano.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    )));
    await _audioPlayer.stop();
    if (mounted) setState(() {});
  }

  Widget _durationSlider(BuildContext context, String label, int value, int min, int max, ValueChanged<int> onChanged) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('$label: $value min'), Text('$min–$max min', style: Theme.of(context).textTheme.bodySmall)]),
    Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), divisions: max - min, label: '$value min', onChanged: (value) => onChanged(value.round())),
  ]);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Theme(
      data: _darkMode ? TempoVivoAppTheme.dark : TempoVivoAppTheme.light,
      child: Scaffold(
      appBar: AppBar(title: Row(children: [const Icon(Icons.wb_sunny_rounded, color: Color(0xFFE8A947)), const SizedBox(width: 10), Text('Tempo Vivo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))]), actions: [IconButton(tooltip: 'Preferências', onPressed: _showSettings, icon: const Icon(Icons.tune_rounded)), const SizedBox(width: 8)]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1200), child: _tab == 0 ? _dashboard(wide) : _otherTab()))),
      floatingActionButton: _tab == 0 ? FloatingActionButton.extended(onPressed: () => _addActivity(weekday: DateTime.now().weekday), icon: const Icon(Icons.add), label: Text('Bloco de tempo')) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: _tab, onDestinationSelected: (index) => setState(() => _tab = index), destinations: const [
        NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Hoje'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Semana'),
        NavigationDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: 'Métodos'),
      ]),
      ),
    );
  }

  Widget _dashboard(bool wide) {
    final agenda = _agendaPanel();
    final focus = _focusPanel();
    final content = wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 6, child: agenda), const SizedBox(width: 20), Expanded(flex: 4, child: focus)]) : Column(children: [focus, const SizedBox(height: 18), agenda]);
    return LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(padding: EdgeInsets.all(wide ? 24 : 16), child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: content)));
  }

  Widget _agendaPanel() {
    final now = DateTime.now();
    final today = _activities.where((item) => item.weekday == null || item.weekday == now.weekday).toList()..sort((a, b) => a.start.hour * 60 + a.start.minute - b.start.hour * 60 - b.start.minute);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Blocos de hoje', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text('${_weekday(now.weekday)}, ${now.day} de ${_month(now.month)}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 12), _priorityCard(compact: true),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(children: [Row(children: [Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Text('${today.where((a) => a.done).length} de ${today.length} blocos concluídos', style: const TextStyle(fontWeight: FontWeight.w600))), Text('${today.isEmpty ? 0 : (today.where((a) => a.done).length * 100 / today.length).round()}%', style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 12), LinearProgressIndicator(value: today.isEmpty ? 0 : today.where((a) => a.done).length / today.length, minHeight: 7, borderRadius: BorderRadius.circular(8))]))),
      const SizedBox(height: 8), ...today.map(_activityTile), const SizedBox(height: 80),
    ]);
  }

  Widget _activityTile(Activity activity) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    SizedBox(width: 65, child: Padding(padding: const EdgeInsets.only(top: 16), child: Text(_time(activity.start), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)))),
    Container(width: 3, margin: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: activity.color, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 10),
    Expanded(child: Card(child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () { setState(() => activity.done = !activity.done); _saveEvents(); }, child: Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(activity.title, style: TextStyle(fontWeight: FontWeight.w600, decoration: activity.done ? TextDecoration.lineThrough : null)), const SizedBox(height: 4), Text('${activity.category} · ${_time(activity.start)}–${_time(activity.end)} · ${activity.minutes} min${activity.weekday == null ? '' : ' · ${_weekday(activity.weekday!)}'}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)), if (activity.steps.isNotEmpty) ...[const SizedBox(height: 8), ...activity.steps.map((step) => Padding(padding: const EdgeInsets.only(bottom: 3), child: Text('• $step', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))))]])), Icon(activity.done ? Icons.check_circle : Icons.radio_button_unchecked, color: activity.done ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline, size: 21),
    ]))))),
  ]));

  Widget _priorityCard({bool compact = false}) => Card(color: Theme.of(context).colorScheme.secondaryContainer, child: Padding(padding: EdgeInsets.all(compact ? 14 : 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text('3 prioridades de hoje', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), if (!compact) Text('${_priorities.where((p) => p.done).length}/3', style: const TextStyle(fontWeight: FontWeight.bold))]),
    ...List.generate(3, (index) => InkWell(onTap: () { setState(() => _priorities[index].done = !_priorities[index].done); _saveEvents(); }, onLongPress: () => _editPriority(index), child: Padding(padding: const EdgeInsets.only(top: 7), child: Row(children: [Icon(_priorities[index].done ? Icons.check_circle : Icons.circle_outlined, size: 19, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text(_priorities[index].title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(decoration: _priorities[index].done ? TextDecoration.lineThrough : null))), IconButton(visualDensity: VisualDensity.compact, tooltip: 'Editar prioridade', onPressed: () => _editPriority(index), icon: const Icon(Icons.edit_outlined, size: 17))])))),
  ])));

  Widget _focusPanel() => Column(children: [
    Card(child: Padding(padding: const EdgeInsets.all(21), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.center_focus_strong, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 9), Expanded(child: Text(_flowMode ? 'Flowtime' : 'Pomodoro', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),), IconButton(tooltip: 'Configurar duração e sons', onPressed: _showSettings, icon: const Icon(Icons.settings_outlined))]),
      SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Pomodoro'), icon: Icon(Icons.timer_outlined)), ButtonSegment(value: true, label: Text('Flowtime'), icon: Icon(Icons.waves))], selected: {_flowMode}, onSelectionChanged: _running ? null : (value) { _resetTimer(); setState(() { _flowMode = value.first; _remaining = _focusMinutes * 60; }); }),
      const SizedBox(height: 18),
      Center(child: SizedBox(width: 186, height: 186, child: Stack(alignment: Alignment.center, children: [SizedBox.expand(child: CircularProgressIndicator(value: _flowMode ? (_running ? null : 0) : 1 - _remaining / ((_isBreak ? _breakMinutes : _focusMinutes) * 60), strokeWidth: 9, strokeCap: StrokeCap.round, backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, color: Theme.of(context).colorScheme.primary)), Column(mainAxisSize: MainAxisSize.min, children: [Text(_flowMode ? _clockFromSeconds(_flowElapsed) : _clock, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()])), const SizedBox(height: 4), Text(_flowMode ? (_running ? 'FLUINDO' : 'ATÉ A PAUSA') : (_isBreak ? 'PAUSA' : 'FOCO'), style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 2, color: Theme.of(context).colorScheme.onSurfaceVariant))])]))),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [FilledButton.icon(onPressed: _toggleTimer, icon: Icon(_running ? Icons.pause : Icons.play_arrow), label: Text(_running && _flowMode ? 'Encerrar sessão' : _running ? 'Pausar' : _flowMode && _flowPaused ? 'Nova sessão' : 'Iniciar')), const SizedBox(width: 8), OutlinedButton.icon(onPressed: _resetTimer, icon: const Icon(Icons.restart_alt), label: Text('Reiniciar'))]),
      const SizedBox(height: 10),
      Center(child: Text(_flowMode ? 'Estude até um ponto natural de pausa' : 'Ciclos de $_focusMinutes min de foco · $_breakMinutes min de pausa', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
      Center(child: TextButton.icon(onPressed: _showSettings, icon: const Icon(Icons.music_note, size: 17), label: Text(_soundEnabled ? _soundName : 'Som desativado'))),
    ]))),
    const SizedBox(height: 14),
    _reviewCard(),
    const SizedBox(height: 14),
    _tipCard(),
  ]);

  Widget _reviewCard() {
    final pending = _reviews.where((review) => !review.done).toList()..sort((a, b) => a.due.compareTo(b.due));
    return Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.psychology_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text('Revisão espaçada', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), IconButton(tooltip: 'Agendar revisão', onPressed: _addReview, icon: const Icon(Icons.add_circle_outline))]),
      Text('Recupere o conteúdo de memória antes de conferir as respostas.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      if (pending.isEmpty) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Tudo revisado. Adicione um assunto para planejar a próxima revisão.')),
      ...pending.take(3).map((review) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.quiz_outlined), title: Text(review.topic), subtitle: Text('${_dueLabel(review.due)} · tente responder sem consultar'), trailing: IconButton(tooltip: 'Iniciar recuperação ativa', icon: const Icon(Icons.play_circle_outline), onPressed: () => _startRecall(review)))),
      ..._reviews.where((review) => review.done).take(2).map((review) => ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary), title: Text(review.topic), subtitle: Text('Revisão concluída'), trailing: TextButton(onPressed: () async { final next = await showDialog<int>(context: context, builder: (dialogContext) => SimpleDialog(title: Text('Agendar próxima revisão'), children: [1, 3, 7, 14, 30].map((days) => SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, days), child: Text('Em $days ${days == 1 ? 'dia' : 'dias'}'))).toList())); if (next != null && mounted) { setState(() { review.due = DateTime.now().add(Duration(days: next)); review.done = false; }); _saveEvents(); } }, child: Text('Reagendar'))),
    ])));
  }

  Future<void> _startRecall(ReviewPlan review) async {
    final controller = TextEditingController();
    final response = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Recupere: ${review.topic}'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [if (review.prompt.isNotEmpty) Text(review.prompt), const SizedBox(height: 12), TextField(controller: controller, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: 'Escreva ou explique o que lembra', border: OutlineInputBorder()))]),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Continuar depois')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Conferi minha resposta'))],
    ));
    controller.dispose();
    if (response == true) {
      if (!mounted) return;
      setState(() => review.done = true);
      _saveEvents();
      final next = await showDialog<int>(context: context, builder: (dialogContext) => SimpleDialog(title: Text('Quando revisar novamente?'), children: [1, 3, 7, 14, 30].map((days) => SimpleDialogOption(onPressed: () => Navigator.pop(dialogContext, days), child: Text('Em $days ${days == 1 ? 'dia' : 'dias'}'))).toList()));
      if (next != null && mounted) { setState(() { review.due = DateTime.now().add(Duration(days: next)); review.done = false; }); _saveEvents(); }
    }
  }

  String _dueLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(date);
    if (due == today) return 'Hoje';
    if (due == today.add(const Duration(days: 1))) return 'Amanhã';
    return '${due.day}/${due.month}';
  }

  Widget _tipCard() => Card(color: Theme.of(context).colorScheme.secondaryContainer, child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.tips_and_updates_outlined, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text('Aprendizagem com prática', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]), const SizedBox(height: 8), Text('Tente explicar o assunto sem olhar suas anotações. Depois, confira o que faltou e agende uma nova revisão.'), const SizedBox(height: 8), Text('Recuperação ativa + repetição espaçada', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600))])));

  Widget _otherTab() => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760), child: _tab == 1 ? _weekPage() : _methodsPage())));

  Widget _weekPage() {
    final days = List.generate(7, (index) => index + 1);
    final dayItems = _activities.where((item) => item.weekday == _weeklyDay).toList()..sort((a, b) => a.start.hour * 60 + a.start.minute - b.start.hour * 60 - b.start.minute);
    final datedEvents = _events.where((event) => DateUtils.isSameDay(event.startsAt, _selectedDate)).toList()..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Agenda', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), Text('Escolha uma data, registre eventos e anotações e reserve blocos recorrentes para sua rotina.'),
      const SizedBox(height: 10),
      Card(child: CalendarDatePicker(initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100), onDateChanged: (date) => setState(() { _selectedDate = DateUtils.dateOnly(date); _weeklyDay = date.weekday; }))),
      Row(children: [Expanded(child: Text('Eventos · ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))), FilledButton.tonalIcon(onPressed: _addEvent, icon: const Icon(Icons.event_note), label: const Text('Novo evento'))]),
      if (!_loaded) const LinearProgressIndicator(),
      if (datedEvents.isEmpty && _loaded) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Nenhum evento nesta data. Toque em “Novo evento” para adicionar um compromisso ou uma anotação.'))),
      ...datedEvents.map((event) => Card(margin: const EdgeInsets.only(top: 8), child: ListTile(leading: IconButton(tooltip: event.done ? 'Marcar como pendente' : 'Marcar como concluído', icon: Icon(event.done ? Icons.check_circle : Icons.radio_button_unchecked, color: Theme.of(context).colorScheme.primary), onPressed: () => _toggleEvent(event)), title: Text(event.title, style: TextStyle(decoration: event.done ? TextDecoration.lineThrough : null, fontWeight: FontWeight.w600)), subtitle: Text('${TimeOfDay.fromDateTime(event.startsAt).format(context)}${event.note.isEmpty ? '' : '\n${event.note}'}'), isThreeLine: event.note.isNotEmpty, trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(tooltip: 'Editar evento', onPressed: () => _editEvent(event), icon: const Icon(Icons.edit_outlined)), IconButton(tooltip: 'Excluir evento', onPressed: () => _deleteEvent(event), icon: const Icon(Icons.delete_outline))])))),
      const SizedBox(height: 24),
      Text('Blocos semanais', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), Text('Blocos recorrentes para aulas, estudo, trabalho, descanso e diversão.'),
      const SizedBox(height: 14), SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: days.map((day) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(_weekday(day).substring(0, 3)), selected: _weeklyDay == day, onSelected: (_) => setState(() => _weeklyDay = day))).toList())),
      const SizedBox(height: 12), Row(children: [Expanded(child: Text(_weekday(_weeklyDay), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))), FilledButton.tonalIcon(onPressed: () => _addActivity(weekday: _weeklyDay), icon: const Icon(Icons.add), label: Text('Adicionar bloco'))]),
      if (dayItems.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Ainda sem blocos neste dia. Reserve um horário para algo importante e também para descansar.'))),
      ...dayItems.map(_activityTile),
      const SizedBox(height: 18), _ifThenCard(), const SizedBox(height: 18), _weeklyGuidance(),
    ]);
  }

  Widget _ifThenCard() => Card(color: Theme.of(context).colorScheme.secondaryContainer, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.alt_route, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text('Plano “se… então…”', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), IconButton(onPressed: () async { final value = await _askText('Plano para imprevistos', initial: _ifThen, hint: 'Se acontecer X, farei Y'); if (value != null && value.isNotEmpty) { setState(() => _ifThen = value); _saveEvents(); } }, icon: const Icon(Icons.edit_outlined))]), const SizedBox(height: 8), Text(_ifThen)])));

  Widget _weeklyGuidance() => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Revisão da semana', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 7), Text('1. Escolha os resultados importantes.\n2. Reserve blocos realistas na agenda.\n3. Inclua pausas e tempo livre.\n4. Prepare uma alternativa para imprevistos.\n5. Revise o plano no fim da semana.')])));

  Widget _methodsPage() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Métodos de gestão do tempo', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text('Use os métodos como ferramentas flexíveis. Escolha o que atende à tarefa e à sua energia.'), const SizedBox(height: 16), _priorityCard(), const SizedBox(height: 10), _eisenhowerCard(), const SizedBox(height: 10), _reviewCard(), const SizedBox(height: 10), _methodInfo(Icons.view_agenda_outlined, 'Time Blocking', 'Reserve horários específicos para aulas, tarefas, exercício, descanso e diversão. Os blocos aparecem na agenda semanal e podem incluir etapas.'), _methodInfo(Icons.timer_outlined, 'Pomodoro', 'Alterne períodos definidos de concentração com pausas. Ajuste a duração nas preferências de foco.'), _methodInfo(Icons.waves, 'Flowtime', 'Inicie o foco e trabalhe até chegar a um ponto natural de pausa. Ao encerrar, o app mostra o tempo focado e sugere um intervalo proporcional.'), _methodInfo(Icons.psychology_outlined, 'Recuperação ativa e repetição espaçada', 'Agende um assunto, tente recuperá-lo de memória sem consultar o material e escolha quando fará a próxima revisão.'), _methodInfo(Icons.event_repeat, 'Planejamento semanal e intenção de implementação', 'Planeje quando e onde fará uma tarefa. Escreva um plano alternativo no formato “Se X acontecer, então farei Y”.')]);

  Widget _eisenhowerCard() {
    final labels = ['Fazer agora', 'Agendar', 'Delegar', 'Reduzir ou eliminar'];
    final groups = List.generate(4, (_) => <EisenhowerTask>[]);
    for (final task in _eisenhower) { groups[task.important ? (task.urgent ? 0 : 1) : (task.urgent ? 2 : 3)].add(task); }
    return Card(child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.grid_view_rounded, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Expanded(child: Text('Matriz de Eisenhower', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))), IconButton(tooltip: 'Adicionar tarefa', onPressed: _addEisenhowerTask, icon: const Icon(Icons.add_circle_outline))]),
      Text('Classifique pela urgência e importância para decidir o próximo passo.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, constraints) { final columns = constraints.maxWidth >= 560; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 4, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns ? 2 : 1, crossAxisSpacing: 8, mainAxisSpacing: 8, mainAxisExtent: 128), itemBuilder: (context, index) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(labels[index], style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: groups[index].isEmpty ? [Text('Sem tarefas', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))] : groups[index].map((task) => Padding(padding: const EdgeInsets.only(top: 4), child: Text('• ${task.title}', style: const TextStyle(fontSize: 12)))).toList())))]))); }),
      const SizedBox(height: 8), FilledButton.tonalIcon(onPressed: _addEisenhowerTask, icon: const Icon(Icons.add), label: Text('Classificar tarefa')),
    ])));
  }

  Widget _methodInfo(IconData icon, String title, String body) => Card(margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(17), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(body, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))]))])));

  String _weekday(int day) => const ['', 'segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'][day];
  String _month(int month) => const ['', 'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'][month];
}

class _EisenhowerQuestionDialog extends StatefulWidget {
  @override
  State<_EisenhowerQuestionDialog> createState() => _EisenhowerQuestionDialogState();
}

class _EisenhowerQuestionDialogState extends State<_EisenhowerQuestionDialog> {
  bool urgent = false;
  bool important = false;
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('Classifique a tarefa'), content: Column(mainAxisSize: MainAxisSize.min, children: [SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('É urgente?'), value: urgent, onChanged: (value) => setState(() => urgent = value)), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('É importante?'), value: important, onChanged: (value) => setState(() => important = value))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, (urgent, important)), child: Text('Classificar'))]);
}

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key});
  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class EventDialog extends StatefulWidget {
  const EventDialog({super.key, required this.initialDate, this.existing});
  final DateTime initialDate;
  final CalendarEvent? existing;
  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late DateTime _when;
  bool _reminder = true;
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _when = existing?.startsAt ?? DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 9);
    _title.text = existing?.title ?? '';
    _note.text = existing?.note ?? '';
    _reminder = existing?.reminder ?? true;
  }
  @override
  void dispose() { _title.dispose(); _note.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text(widget.existing == null ? 'Novo evento' : 'Editar evento'), content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextField(controller: _title, autofocus: true, decoration: const InputDecoration(labelText: 'Nome do evento')),
    const SizedBox(height: 8), TextField(controller: _note, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Anotação', hintText: 'Local, preparação ou detalhes')),
    const SizedBox(height: 10), OutlinedButton.icon(onPressed: () async { final date = await showDatePicker(context: context, initialDate: _when, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (date == null || !context.mounted) return; final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when)); if (time != null) setState(() => _when = DateTime(date.year, date.month, date.day, time.hour, time.minute)); }, icon: const Icon(Icons.schedule), label: Text('${_when.day}/${_when.month}/${_when.year} · ${TimeOfDay.fromDateTime(_when).format(context)}')),
    SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Lembrete no horário'), value: _reminder, onChanged: (value) => setState(() => _reminder = value)),
  ]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () { if (_title.text.trim().isEmpty) return; Navigator.pop(context, CalendarEvent(id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.remainder(2147483647), title: _title.text.trim(), startsAt: _when, note: _note.text.trim(), done: widget.existing?.done ?? false, reminder: _reminder)); }, child: const Text('Salvar evento'))]);
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _topic = TextEditingController();
  final _prompt = TextEditingController();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  @override
  void dispose() { _topic.dispose(); _prompt.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('Agendar revisão'), content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: _topic, autofocus: true, decoration: const InputDecoration(labelText: 'Assunto para revisar')), const SizedBox(height: 8), TextField(controller: _prompt, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Pergunta para recuperar de memória')), const SizedBox(height: 8), OutlinedButton.icon(onPressed: () async { final date = await showDatePicker(context: context, initialDate: _date, firstDate: DateUtils.dateOnly(DateTime.now()), lastDate: DateTime.now().add(const Duration(days: 365))); if (date != null) setState(() => _date = date); }, icon: const Icon(Icons.calendar_today), label: Text('Revisar em ${_date.day}/${_date.month}/${_date.year}'))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')), FilledButton(onPressed: () { if (_topic.text.trim().isEmpty) return; Navigator.pop(context, ReviewPlan(topic: _topic.text.trim(), due: _date, prompt: _prompt.text.trim())); }, child: Text('Agendar'))]);
}

class ActivityDialog extends StatefulWidget {
  const ActivityDialog({super.key, this.initialWeekday});
  final int? initialWeekday;
  @override
  State<ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<ActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _steps = TextEditingController();
  String _category = 'Estudo';
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  int? _weekday;
  final _colors = const [Color(0xFF68A88B), Color(0xFF7895C8), Color(0xFFE9A66B), Color(0xFFB08BC3)];
  @override
  void initState() { super.initState(); _weekday = widget.initialWeekday; }
  @override
  void dispose() { _title.dispose(); _steps.dispose(); super.dispose(); }
  Future<void> _pickTime(bool start) async { final picked = await showTimePicker(context: context, initialTime: start ? _start : _end); if (picked != null) setState(() { if (start) { _start = picked; } else { _end = picked; } }); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('Novo bloco de tempo'), content: SizedBox(width: 440, child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
    TextFormField(controller: _title, autofocus: true, decoration: const InputDecoration(labelText: 'Atividade', prefixIcon: Icon(Icons.edit_note)), validator: (value) => value == null || value.trim().isEmpty ? 'Informe uma atividade' : null),
    const SizedBox(height: 10), DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Categoria'), items: const ['Estudo', 'Aula', 'Trabalho', 'Exercício', 'Rotina', 'Pausa', 'Diversão', 'Pessoal'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) { if (value != null) setState(() => _category = value); }),
    const SizedBox(height: 8), DropdownButtonFormField<int?>(initialValue: _weekday, decoration: const InputDecoration(labelText: 'Dia da semana (vazio = sem repetição)'), items: [const DropdownMenuItem<int?>(value: null, child: Text('Não repetir')), ...List.generate(7, (index) => DropdownMenuItem<int?>(value: index + 1, child: Text(const ['', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'][index + 1])))], onChanged: (value) => setState(() => _weekday = value)),
    const SizedBox(height: 8), Row(children: [Expanded(child: OutlinedButton.icon(onPressed: () => _pickTime(true), icon: const Icon(Icons.schedule), label: Text(_start.format(context)))), const Padding(padding: EdgeInsets.symmetric(horizontal: 7), child: Text('até')), Expanded(child: OutlinedButton.icon(onPressed: () => _pickTime(false), icon: const Icon(Icons.schedule), label: Text(_end.format(context))))]),
    const SizedBox(height: 8), TextField(controller: _steps, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Etapas (opcional)', hintText: 'Uma etapa por linha', prefixIcon: Icon(Icons.format_list_bulleted))),
  ])))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')), FilledButton(onPressed: () { if (!_formKey.currentState!.validate()) return; if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O término deve ser depois do início.'))); return; } Navigator.pop(context, Activity(title: _title.text.trim(), category: _category, start: _start, end: _end, color: _colors[DateTime.now().second % _colors.length], weekday: _weekday, steps: _steps.text.split('\n').map((step) => step.trim()).where((step) => step.isNotEmpty).toList())); }, child: Text('Adicionar'))]);
}
