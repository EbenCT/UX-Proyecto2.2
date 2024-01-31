import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.red, // Colores del segundo proyecto
        //accentColor: Colors.white,
        backgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterTts _flutterTts = FlutterTts();
  SpeechToText _speechToText = SpeechToText();

  List<Map> _voices = [];
  Map? _currentVoice;

  int? _currentWordStart, _currentWordEnd;

  TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initTTS();
    initSpeech();
  }

  void initTTS() {
    _flutterTts.setProgressHandler((text, start, end, word) {
      setState(() {
        _currentWordStart = start;
        _currentWordEnd = end;
      });
    });
    _flutterTts.getVoices.then((data) {
      try {
        List<Map> voices = List<Map>.from(data);
        setState(() {
          _voices =
              voices.where((voice) => voice["locale"]?.startsWith("es") ?? false).toList();
          if (_voices.isNotEmpty) {
            _currentVoice = _voices.first;
            setVoice(_currentVoice!);
          }
        });
      } catch (e) {
        print(e);
      }
    });
  }

  void initSpeech() async {
    _speechToText = SpeechToText();
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {});
    }
  }

  void setVoice(Map voice) {
    _flutterTts.setVoice({"name": voice["name"], "locale": voice["locale"]});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _currentWordStart = null;
      _currentWordEnd = null;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _textEditingController.text = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          'UX-Proyecto2',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: _buildUI(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed:
                _speechToText.isListening ? _stopListening : _startListening,
            tooltip: 'Listen',
            child: Icon(
              _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              _flutterTts.speak(_textEditingController.text);
            },
            child: Icon(
              Icons.speaker_phone,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _textInputField(),
          _speakerSelector(),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 20,
                color: Colors.black,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: _textEditingController.text.substring(0, _currentWordStart),
                ),
                if (_currentWordStart != null)
                  TextSpan(
                    text: _textEditingController.text.substring(
                        _currentWordStart!, _currentWordEnd),
                    style: const TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.purpleAccent,
                    ),
                  ),
                if (_currentWordEnd != null)
                  TextSpan(
                    text: _textEditingController.text.substring(_currentWordEnd!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _textEditingController,
        decoration: InputDecoration(
          hintText: "Ingrese el texto",
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _speakerSelector() {
    return DropdownButton(
      value: _currentVoice,
      items: _voices
          .map(
            (_voice) => DropdownMenuItem(
              value: _voice,
              child: Text(
                _voice["name"],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _currentVoice = value;
          setVoice(_currentVoice!);
        });
      },
    );
  }
}
