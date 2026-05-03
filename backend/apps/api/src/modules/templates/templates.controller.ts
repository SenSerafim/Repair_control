import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TemplatesService } from './templates.service';

/**
 * П1.7 / П4.6 — пользовательские шаблоны и «сохранить как шаблон» удалены из MVP.
 * Endpoint'ы:
 *   GET  /templates/platform   — список 8 платформенных шаблонов (П4.5).
 *   GET  /templates/:id        — детальный template (для применения в wizard'е).
 *
 * Удалены:
 *   - GET  /templates/user           — выдача user-шаблонов больше не делается;
 *     если в БД остались записи kind='user', они скрыты на уровне сервиса.
 *   - POST /templates/:id/apply      — применение через сервис, прямого endpoint'а не было нужно;
 *     UI создаёт этап копированием полей шаблона в POST /projects/:id/stages.
 *   - POST /templates/from-stage/:id — saveFromStage больше нет.
 */
@ApiTags('templates')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('templates')
export class TemplatesController {
  constructor(private readonly templates: TemplatesService) {}

  @Get('platform')
  async platform() {
    return this.templates.listPlatform();
  }

  @Get(':id')
  async get(@Param('id') id: string) {
    return this.templates.get(id);
  }
}
