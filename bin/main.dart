import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:nyxx/nyxx.dart';

void main(List<String> arguments) {
  var dictionary = jsonDecode(File('dictionary.json').readAsStringSync());

  const token = '';
  //TODO: replace token with your own bot token

  final bot =
      NyxxFactory.createNyxxWebsocket(token, GatewayIntents.allUnprivileged)
        ..registerPlugin(Logging()) // Default logging plugin
        ..registerPlugin(
            CliIntegration()) // Cli integration for nyxx allows stopping application via SIGTERM and SIGKILl
        ..registerPlugin(
            IgnoreExceptions()) // Plugin that handles uncaught exceptions that may occur
        ..connect();

  // Listen to ready event. Invoked when bot is connected to all shards. Note that cache can be empty or not incomplete.
  bot.eventsWs.onReady.listen((IReadyEvent e) {
    print("Ready!");
  });

  //Here are the words to trigger the bot in chat
  const triggers = [
    'нейротортик',
    'python',
    'питон',
    'пайтон',
    'питонизм',
    'мопс'
  ];

  //Listen to all incoming messages
  bot.eventsWs.onMessageReceived.listen((IMessageReceivedEvent e) async {
    //This is used to send a bot's catchphrase every 150 messages in average.
    if (tossD150()) {
      final messageBuilder = MessageBuilder.content('Я ем блины со сметаной');
      Future.delayed(Duration(milliseconds: 3000),
          () => e.message.channel.sendMessage(messageBuilder));
    } else {
      //This is needed to prevent an endless loop of bots replying to each other
      //(if you have more than one)
      if (!e.message.author.bot) {
        if (e.message.referencedMessage?.message?.author.id == bot.self.id ||
            checkIfBotTriggered(e.message.content, triggers)) {
          final replyBuilder = ReplyBuilder.fromMessage(e.message);
          var phrase = generatePhrase(dictionary);
          final messageBuilder = MessageBuilder.content(phrase)
            ..replyBuilder = replyBuilder;

          final allowedMentionsBuilder = AllowedMentions()..allow(reply: false);
          messageBuilder.allowedMentions = allowedMentionsBuilder;

          //Logging
          print('Боту написали: ${e.message.content}\n');
          print('Боту ответил: $phrase \n\n');

          Future.delayed(Duration(milliseconds: 1500),
              () => e.message.channel.sendMessage(messageBuilder));
        }
      }
    }
  });
}

//Yes, this is merely a 150-sided dice.
bool tossD150() {
  if (Random().nextInt(150) == 0) {
    return true;
  }
  return false;
}

bool checkIfBotTriggered(String message, List<String> triggers) {
  for (var t in triggers) {
    if (message.toLowerCase().contains(t)) {
      return true;
    }
  }
  return false;
}

String generatePhrase(dynamic dictionary) {
  String w = 'start';

  List<String> _phrase = [];

  while (w != 'end') {
    if (w != 'start') {
      _phrase.add(w);
    } else {
      _phrase.add(' ');
    }
    var p = Random().nextDouble();

    double s = 0;

    for (var _w in dictionary[w]!.keys) {
      s += dictionary[w]![_w]!;
      if (s > p) {
        w = _w;

        break;
      }
    }
  }
  return _phrase.reduce((out, w) {
    if (w != 'start' && w != 'end') {
      out += w + ' ';
    }
    return out
        .replaceAll(' ,', ',')
        .replaceAll(' .', '.')
        .replaceAll(' ?', '?')
        .replaceAll(' !', '!');
  });
}
