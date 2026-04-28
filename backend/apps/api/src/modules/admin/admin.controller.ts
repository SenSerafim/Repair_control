import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiProperty, ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '@nestjs/passport';
import { IsInt, IsOptional, IsString, Length, Min } from 'class-validator';
import { AccessGuard, RequireAccess } from '@app/rbac';
import { AdminService } from './admin.service';

class CreateFaqSectionDto {
  @ApiProperty()
  @IsString()
  @Length(1, 200)
  title!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  orderIndex!: number;
}

class CreateFaqItemDto {
  @ApiProperty()
  @IsString()
  sectionId!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 500)
  question!: string;

  @ApiProperty()
  @IsString()
  @Length(1, 5000)
  answer!: string;

  @ApiProperty()
  @IsInt()
  @Min(0)
  orderIndex!: number;
}

class UpdateFaqItemDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 500)
  question?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @Length(1, 5000)
  answer?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  orderIndex?: number;
}

class PutSettingDto {
  @ApiProperty()
  @IsString()
  @Length(1, 100)
  key!: string;

  @ApiProperty()
  @IsString()
  @Length(0, 2000)
  value!: string;
}

@ApiTags('admin')
@ApiBearerAuth()
@UseGuards(AuthGuard('jwt'), AccessGuard)
@Controller()
export class AdminController {
  constructor(private readonly svc: AdminService) {}

  // ---------- FAQ ----------

  @Get('admin/faq-sections')
  @RequireAccess({ action: 'admin.faq.manage', resource: 'none' })
  listFaq() {
    return this.svc.listFaqSections();
  }

  @Post('admin/faq-sections')
  @RequireAccess({ action: 'admin.faq.manage', resource: 'none' })
  createSection(@Body() dto: CreateFaqSectionDto, @Req() req: any) {
    return this.svc.createFaqSection(req.user.userId, dto.title, dto.orderIndex);
  }

  @Post('admin/faq-items')
  @RequireAccess({ action: 'admin.faq.manage', resource: 'none' })
  createItem(@Body() dto: CreateFaqItemDto, @Req() req: any) {
    return this.svc.createFaqItem(
      req.user.userId,
      dto.sectionId,
      dto.question,
      dto.answer,
      dto.orderIndex,
    );
  }

  @Patch('admin/faq-items/:id')
  @RequireAccess({ action: 'admin.faq.manage', resource: 'none' })
  updateItem(@Param('id') id: string, @Body() dto: UpdateFaqItemDto, @Req() req: any) {
    return this.svc.updateFaqItem(req.user.userId, id, dto);
  }

  @Delete('admin/faq-items/:id')
  @RequireAccess({ action: 'admin.faq.manage', resource: 'none' })
  async deleteItem(@Param('id') id: string, @Req() req: any) {
    await this.svc.deleteFaqItem(req.user.userId, id);
    return { deleted: true };
  }

  // ---------- Public FAQ (list for users) ----------

  @Get('faq')
  @UseGuards(AuthGuard('jwt'))
  publicFaq() {
    return this.svc.listFaqSections();
  }

  @Get('faq/:id')
  @UseGuards(AuthGuard('jwt'))
  publicFaqItem(@Param('id') id: string) {
    return this.svc.getFaqItem(id);
  }

  // ---------- App Settings ----------

  @Get('admin/settings')
  @RequireAccess({ action: 'admin.settings.manage', resource: 'none' })
  listSettings() {
    return this.svc.listSettings();
  }

  @Put('admin/settings')
  @RequireAccess({ action: 'admin.settings.manage', resource: 'none' })
  putSetting(@Body() dto: PutSettingDto, @Req() req: any) {
    return this.svc.putSetting(req.user.userId, dto.key, dto.value);
  }

  @Get('me/app-settings')
  @UseGuards(AuthGuard('jwt'))
  me() {
    return this.svc.getPublicSettings();
  }
}
