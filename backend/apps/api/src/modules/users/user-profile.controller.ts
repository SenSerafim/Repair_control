import { Controller, Get, Param, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { UserProfileService } from './user-profile.service';

/**
 * ТЗ NEWFIX §4 — `GET /users/:id/profile-aggregate`.
 * Отдельный контроллер, потому что UsersController сидит на `/me`.
 * Видимость и role-gating секций живут в UserProfileService.
 */
@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UserProfileController {
  constructor(private readonly profile: UserProfileService) {}

  @Get(':id/profile-aggregate')
  async aggregate(@Req() req: { user: AuthenticatedUser }, @Param('id') id: string) {
    return this.profile.getAggregate(req.user.userId, id);
  }
}
