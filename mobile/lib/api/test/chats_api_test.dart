import 'package:test/test.dart';
import 'package:repair_control_api/repair_control_api.dart';

/// tests for ChatsApi
void main() {
  final instance = RepairControlApi().getChatsApi();

  group(ChatsApi, () {
    //Future chatsControllerAddParticipant(String chatId, AddParticipantDto addParticipantDto) async
    test('test chatsControllerAddParticipant', () async {
      // TODO
    });

    //Future chatsControllerCreateGroup(String projectId, CreateGroupChatDto createGroupChatDto) async
    test('test chatsControllerCreateGroup', () async {
      // TODO
    });

    //Future chatsControllerCreatePersonal(String projectId, CreatePersonalChatDto createPersonalChatDto) async
    test('test chatsControllerCreatePersonal', () async {
      // TODO
    });

    //Future chatsControllerDeleteMessage(String chatId, String id) async
    test('test chatsControllerDeleteMessage', () async {
      // TODO
    });

    //Future chatsControllerEditMessage(String chatId, String id, EditMessageDto editMessageDto) async
    test('test chatsControllerEditMessage', () async {
      // TODO
    });

    //Future chatsControllerForward(String chatId, String id, ForwardMessageDto forwardMessageDto) async
    test('test chatsControllerForward', () async {
      // TODO
    });

    //Future chatsControllerGet(String chatId) async
    test('test chatsControllerGet', () async {
      // TODO
    });

    //Future chatsControllerList(String projectId) async
    test('test chatsControllerList', () async {
      // TODO
    });

    //Future chatsControllerListMessages(String chatId, { String cursor, num limit }) async
    test('test chatsControllerListMessages', () async {
      // TODO
    });

    //Future chatsControllerMarkRead(String chatId, MarkReadDto markReadDto) async
    test('test chatsControllerMarkRead', () async {
      // TODO
    });

    //Future chatsControllerPatch(String chatId, PatchChatDto patchChatDto) async
    test('test chatsControllerPatch', () async {
      // TODO
    });

    //Future chatsControllerPostMessage(String chatId, CreateMessageDto createMessageDto) async
    test('test chatsControllerPostMessage', () async {
      // TODO
    });

    //Future chatsControllerRemoveParticipant(String chatId, String userId) async
    test('test chatsControllerRemoveParticipant', () async {
      // TODO
    });
  });
}
