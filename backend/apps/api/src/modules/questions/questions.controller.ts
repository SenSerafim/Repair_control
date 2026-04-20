import { Body, Controller, Get, Param, Post, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { QuestionsService } from './questions.service';
import { AnswerQuestionDto, AskQuestionDto } from './dto';

@ApiTags('questions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, AccessGuard)
@Controller()
export class QuestionsController {
  constructor(private readonly questions: QuestionsService) {}

  @Post('steps/:stepId/questions')
  @RequireAccess({
    action: 'question.manage',
    resource: 'step',
    resourceIdFrom: { source: 'params', key: 'stepId' },
  })
  async ask(
    @Req() req: { user: AuthenticatedUser },
    @Param('stepId') stepId: string,
    @Body() dto: AskQuestionDto,
  ) {
    return this.questions.ask(stepId, dto.addresseeId, dto.text, req.user.userId);
  }

  @Get('steps/:stepId/questions')
  async listForStep(@Param('stepId') stepId: string) {
    return this.questions.listForStep(stepId);
  }

  @Post('questions/:id/answer')
  async answer(
    @Req() req: { user: AuthenticatedUser },
    @Param('id') id: string,
    @Body() dto: AnswerQuestionDto,
  ) {
    return this.questions.answer(id, dto.answer, req.user.userId);
  }

  @Post('questions/:id/close')
  async close(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.questions.close(id, req.user.userId);
  }

  @Get('me/questions')
  async listMine(
    @Req() req: { user: AuthenticatedUser },
    @Query('filter') filter?: 'inbox' | 'sent' | 'open' | 'closed',
  ) {
    return this.questions.listForUser(req.user.userId, filter);
  }
}
