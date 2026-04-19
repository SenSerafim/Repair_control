import { Module } from '@nestjs/common';
import { FilesApiController } from './files-api.controller';

@Module({
  controllers: [FilesApiController],
})
export class FilesApiModule {}
