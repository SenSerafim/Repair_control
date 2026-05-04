import { forwardRef, Module } from '@nestjs/common';
import { StagesModule } from '../stages/stages.module';
import { SelfPurchasesModule } from '../selfpurchases/selfpurchases.module';
import { PaymentsModule } from '../payments/payments.module';
import { MaterialsModule } from '../materials/materials.module';
import { ApprovalsController } from './approvals.controller';
import { ApprovalsService } from './approvals.service';

@Module({
  imports: [
    forwardRef(() => StagesModule),
    forwardRef(() => SelfPurchasesModule),
    forwardRef(() => PaymentsModule),
    forwardRef(() => MaterialsModule),
  ],
  controllers: [ApprovalsController],
  providers: [ApprovalsService],
  exports: [ApprovalsService],
})
export class ApprovalsModule {}
