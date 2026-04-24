import { Module } from '@nestjs/common';
import { SelfPurchasesController } from './selfpurchases.controller';
import { SelfPurchasesService } from './selfpurchases.service';

@Module({
  controllers: [SelfPurchasesController],
  providers: [SelfPurchasesService],
  exports: [SelfPurchasesService],
})
export class SelfPurchasesModule {}
