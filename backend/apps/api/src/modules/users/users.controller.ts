import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UsersService } from './users.service';
import { AddRoleDto, RegisterDeviceDto, SetActiveRoleDto, UpdateProfileDto } from './dto';
import { AuthenticatedUser } from '../auth/jwt.strategy';
import { SystemRole } from '@app/rbac';

@ApiTags('me')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('me')
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  async me(@Req() req: { user: AuthenticatedUser }) {
    return this.users.getProfile(req.user.userId);
  }

  @Get('teammates')
  async teammates(@Req() req: { user: AuthenticatedUser }) {
    return this.users.listTeammates(req.user.userId);
  }

  @Patch()
  async updateMe(@Req() req: { user: AuthenticatedUser }, @Body() dto: UpdateProfileDto) {
    return this.users.updateProfile(req.user.userId, dto);
  }

  @Get('roles')
  async roles(@Req() req: { user: AuthenticatedUser }) {
    return this.users.listRoles(req.user.userId);
  }

  @Post('roles')
  async addRole(@Req() req: { user: AuthenticatedUser }, @Body() dto: AddRoleDto) {
    return this.users.addRole(req.user.userId, dto.role as SystemRole);
  }

  @Delete('roles/:role')
  async removeRole(@Req() req: { user: AuthenticatedUser }, @Param('role') role: SystemRole) {
    return this.users.removeRole(req.user.userId, role);
  }

  @Put('active-role')
  async setActive(@Req() req: { user: AuthenticatedUser }, @Body() dto: SetActiveRoleDto) {
    return this.users.setActiveRole(req.user.userId, dto.role as SystemRole);
  }

  @Post('devices')
  async addDevice(@Req() req: { user: AuthenticatedUser }, @Body() dto: RegisterDeviceDto) {
    return this.users.registerDevice(req.user.userId, dto);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteMe(@Req() req: { user: AuthenticatedUser }): Promise<void> {
    await this.users.deleteAccount(req.user.userId);
  }
}
