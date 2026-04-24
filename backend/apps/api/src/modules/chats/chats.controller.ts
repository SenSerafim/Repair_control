import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { ChatsService } from './chats.service';
import { MessagesService } from './messages.service';
import { ReadReceiptsService } from './read-receipts.service';
import {
  AddParticipantDto,
  CreateGroupChatDto,
  CreateMessageDto,
  CreatePersonalChatDto,
  EditMessageDto,
  ForwardMessageDto,
  ListMessagesQueryDto,
  MarkReadDto,
  PatchChatDto,
} from './dto';

@ApiTags('chats')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class ChatsController {
  constructor(
    private readonly chats: ChatsService,
    private readonly messages: MessagesService,
    private readonly read: ReadReceiptsService,
  ) {}

  @Get('projects/:projectId/chats')
  @RequireAccess({
    action: 'chat.read',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  list(@Param('projectId') projectId: string, @Req() req: any) {
    return this.chats.listForProject(projectId, req.user.userId);
  }

  @Get('chats/:chatId')
  @RequireAccess({
    action: 'chat.read',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  get(@Param('chatId') chatId: string, @Req() req: any) {
    return this.chats.get(chatId, req.user.userId);
  }

  @Post('projects/:projectId/chats/personal')
  @RequireAccess({
    action: 'chat.create_personal',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  createPersonal(
    @Param('projectId') projectId: string,
    @Body() dto: CreatePersonalChatDto,
    @Req() req: any,
  ) {
    return this.chats.createPersonal(projectId, req.user.userId, dto.withUserId);
  }

  @Post('projects/:projectId/chats/group')
  @RequireAccess({
    action: 'chat.create_group',
    resource: 'project',
    resourceIdFrom: { source: 'params', key: 'projectId' },
  })
  createGroup(
    @Param('projectId') projectId: string,
    @Body() dto: CreateGroupChatDto,
    @Req() req: any,
  ) {
    return this.chats.createGroup(projectId, req.user.userId, dto.title, dto.participantUserIds);
  }

  @Patch('chats/:chatId')
  @RequireAccess({
    action: 'chat.toggle_customer_visibility',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  patch(@Param('chatId') chatId: string, @Body() dto: PatchChatDto, @Req() req: any) {
    return this.chats.patch(chatId, req.user.userId, dto);
  }

  @Post('chats/:chatId/participants')
  @RequireAccess({
    action: 'chat.moderate',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  addParticipant(@Param('chatId') chatId: string, @Body() dto: AddParticipantDto, @Req() req: any) {
    return this.chats.addParticipant(chatId, req.user.userId, dto.userId);
  }

  @Delete('chats/:chatId/participants/:userId')
  @RequireAccess({
    action: 'chat.moderate',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  removeParticipant(
    @Param('chatId') chatId: string,
    @Param('userId') userId: string,
    @Req() req: any,
  ) {
    return this.chats.removeParticipant(chatId, req.user.userId, userId);
  }

  // ---------- messages ----------

  @Get('chats/:chatId/messages')
  @RequireAccess({
    action: 'chat.read',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  listMessages(@Param('chatId') chatId: string, @Query() q: ListMessagesQueryDto, @Req() req: any) {
    return this.messages.list(chatId, req.user.userId, { cursor: q.cursor, limit: q.limit });
  }

  @Post('chats/:chatId/messages')
  @RequireAccess({
    action: 'chat.write',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  postMessage(@Param('chatId') chatId: string, @Body() dto: CreateMessageDto, @Req() req: any) {
    return this.messages.create(chatId, req.user.userId, dto);
  }

  @Patch('chats/:chatId/messages/:id')
  @RequireAccess({
    action: 'chat.write',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  editMessage(
    @Param('chatId') _chatId: string,
    @Param('id') messageId: string,
    @Body() dto: EditMessageDto,
    @Req() req: any,
  ) {
    return this.messages.edit(messageId, req.user.userId, dto.text);
  }

  @Delete('chats/:chatId/messages/:id')
  @RequireAccess({
    action: 'chat.write',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  async deleteMessage(
    @Param('chatId') _chatId: string,
    @Param('id') messageId: string,
    @Req() req: any,
  ) {
    await this.messages.softDelete(messageId, req.user.userId);
    return { deleted: true };
  }

  @Post('chats/:chatId/messages/:id/forward')
  @RequireAccess({
    action: 'chat.write',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  forward(
    @Param('chatId') _chatId: string,
    @Param('id') messageId: string,
    @Body() dto: ForwardMessageDto,
    @Req() req: any,
  ) {
    return this.messages.forward(messageId, dto.toChatId, req.user.userId);
  }

  @Post('chats/:chatId/read')
  @RequireAccess({
    action: 'chat.read',
    resource: 'chat',
    resourceIdFrom: { source: 'params', key: 'chatId' },
  })
  async markRead(@Param('chatId') chatId: string, @Body() dto: MarkReadDto, @Req() req: any) {
    await this.read.markRead(chatId, req.user.userId, dto.messageId);
    return { ok: true };
  }
}
