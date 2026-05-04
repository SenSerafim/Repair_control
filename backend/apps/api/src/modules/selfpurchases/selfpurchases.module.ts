import { forwardRef, Module } from '@nestjs/common';
import { ApprovalsModule } from '../approvals/approvals.module';
import { SelfPurchasesController } from './selfpurchases.controller';
import { SelfPurchasesService } from './selfpurchases.service';

@Module({
  imports: [forwardRef(() => ApprovalsModule)],
  controllers: [SelfPurchasesController],
  providers: [SelfPurchasesService],
  exports: [SelfPurchasesService],
})
export class SelfPurchasesModule {}
