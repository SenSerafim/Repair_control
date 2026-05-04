import { forwardRef, Module } from '@nestjs/common';
import { ApprovalsModule } from '../approvals/approvals.module';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { BudgetCalculator } from './budget-calculator';

@Module({
  imports: [forwardRef(() => ApprovalsModule)],
  controllers: [PaymentsController],
  providers: [PaymentsService, BudgetCalculator],
  exports: [PaymentsService, BudgetCalculator],
})
export class PaymentsModule {}
