import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "SIMAHA`TAHU",
    profileImage:
    "https://seeklogo.com/images/A/ai-buddy-logo-3DB2A531D8-seeklogo.com.png",
  );

  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "SIMAHA`TAHU",
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Column(
      children: [
        Expanded(
          child: DashChat(
            inputOptions: InputOptions(trailing: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(
                  Icons.image,
                ),
              )
            ]),
            currentUser: currentUser,
            onSend: _sendMessage,
            messages: messages,
          ),
        ),
        if (_selectedImage != null) _buildSelectedImagePreview(),
      ],
    );
  }

  Widget _buildSelectedImagePreview() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Image.file(
            _selectedImage!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'add a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendImageMessage,
          ),
        ],
      ),
    );
  }

  final TextEditingController _textController = TextEditingController();

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini
          .streamGenerateContent(
        question,
        images: images,
      )
          .listen((event) {
        ChatMessage? lastMessage = messages.firstOrNull;
        if (lastMessage != null && lastMessage.user == geminiUser) {
          lastMessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
              "", (previous, current) => "$previous ${current.text}") ??
              "";
          lastMessage.text += response;
          setState(
                () {
              messages = [lastMessage!, ...messages];
            },
          );
        } else {
          String response = event.content?.parts?.fold(
              "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: response,
          );
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _pickImage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      setState(() {
        _selectedImage = File(file.path);
      });
    }
  }

  void _sendImageMessage() {
    if (_selectedImage != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: _textController.text,
        medias: [
          ChatMedia(
            url: _selectedImage!.path,
            fileName: "",
            type: MediaType.image,
          )
        ],
      );
      _sendMessage(chatMessage);
      setState(() {
        _selectedImage = null;
        _textController.clear();
      });
    }
  }
}
