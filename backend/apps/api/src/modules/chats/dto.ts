import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsBoolean, IsInt, IsOptional, IsString, Length, Max, Min } from 'class-validator';
import { ChatType } from '@prisma/client';

export class CreatePersonalChatDto {
  @ApiProperty()
  @IsString()
  @Length(1, 100)
  withUserId!: string;
}

export class CreateGroupChatDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty({ type: [String] })
  @IsArray()
  @IsString({ each: true })
  participantUserIds!: string[];
}

export class PatchChatDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 200)
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  visibleToCustomer?: boolean;
}

export class AddParticipantDto {
  @ApiProperty()
  @IsString()
  userId!: string;
}

export class CreateMessageDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(1, 10_000)
  text?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  attachmentKeys?: string[];
}

export class EditMessageDto {
  @ApiProperty()
  @IsString()
  @Length(1, 10_000)
  text!: string;
}

export class ForwardMessageDto {
  @ApiProperty()
  @IsString()
  toChatId!: string;
}

export class MarkReadDto {
  @ApiProperty()
  @IsString()
  messageId!: string;
}

export class ListMessagesQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({ default: 50 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}

export interface SerializedChat {
  id: string;
  type: ChatType;
  projectId: string | null;
  stageId: string | null;
  stage?: { id: string; title: string; orderIndex: number } | null;
  title: string | null;
  visibleToCustomer: boolean;
  createdById: string;
  createdAt: Date;
  participants: { userId: string; joinedAt: Date; leftAt: Date | null }[];
  /** Метаданные последнего сообщения — для inbox-превью и сортировки. */
  lastMessageAt: Date | null;
  lastMessagePreview: string | null;
  lastMessageAuthorId: string | null;
  /** Cnt сообщений с createdAt > GREATEST(joinedAt, lastReadAt), не от
   *  текущего пользователя и не удалённых. Считается на сервере одним
   *  батч-запросом, чтобы у клиента не было N+1 и рассинхрона счётчиков. */
  unreadCount: number;
}

export interface SerializedMessage {
  id: string;
  chatId: string;
  authorId: string;
  text: string | null;
  attachmentKeys: string[];
  forwardedFromId: string | null;
  editedAt: Date | null;
  deletedAt: Date | null;
  createdAt: Date;
}
