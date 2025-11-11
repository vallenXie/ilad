import { InvestmentDirection, CurrencyCode, InvestmentRecord, StockInfo, StockHolding, ExchangeRate } from '../model/StockModels';
import StockStore from '../viewmodel/StockStore';

const SUPPORTED_CURRENCIES: Array<CurrencyCode> = ['CNY', 'USD'];

@Entry
@Component
struct Index {
  @State store: StockStore = StockStore.getInstance();

  @State private stockCode: string = '';
  @State private stockName: string = '';
  @State private stockIcon: string = '';

  @State private investmentStockCode: string = '';
  @State private investmentDirection: InvestmentDirection = InvestmentDirection.BUY;
  @State private investmentQuantity: string = '';
  @State private investmentPrice: string = '';
  @State private investmentCurrency: CurrencyCode = 'CNY';
  @State private investmentNote: string = '';

  @State private adjustmentAmount: string = '';
  @State private adjustmentCurrency: CurrencyCode = 'CNY';
  @State private adjustmentNote: string = '';

  @State private exchangeBase: CurrencyCode = 'CNY';
  @State private exchangeQuote: CurrencyCode = 'USD';
  @State private exchangeRate: string = '';

  @State private feedbackMessage: string = '';
  @State private errorMessage: string = '';

  build() {
    Scroll() {
      Column() {
        this.renderHeader();
        this.renderFeedback();
        this.renderStockSection();
        this.renderInvestmentSection();
        this.renderBalanceSection();
        this.renderExchangeSection();
        this.renderSummary();
      }
      .padding({ left: 16, right: 16, top: 24, bottom: 24 })
      .width('100%');
    }
    .backgroundColor('#F7F8FA');
  }

  private renderHeader(): void {
    Column() {
      Text($r('app.string.app_name'))
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#202020');
      Text($r('app.string.app_description'))
        .fontSize(14)
        .fontColor('#606060')
        .margin({ top: 4 });
    }
    .width('100%')
    .margin({ bottom: 24 });
  }

  private renderFeedback(): void {
    if (this.errorMessage) {
      Text(this.errorMessage)
        .fontSize(14)
        .fontColor(Color.Red)
        .backgroundColor('#FFE8E8')
        .padding(12)
        .borderRadius(8)
        .margin({ bottom: 16 });
    } else if (this.feedbackMessage) {
      Text(this.feedbackMessage)
        .fontSize(14)
        .fontColor('#0D8A1E')
        .backgroundColor('#E8F8EE')
        .padding(12)
        .borderRadius(8)
        .margin({ bottom: 16 });
    }
  }

  private renderStockSection(): void {
    Column() {
      this.sectionTitle($r('app.string.section_stock_header'));
      this.sectionSubtitle($r('app.string.section_stock_subtitle'));

      Column() {
        TextInput({ placeholder: '股票代码（如 600519）', text: this.stockCode })
          .onChange(value => this.stockCode = value.toUpperCase())
          .margin({ bottom: 8 });
        TextInput({ placeholder: '股票名称（如 贵州茅台）', text: this.stockName })
          .onChange(value => this.stockName = value)
          .margin({ bottom: 8 });
        TextInput({ placeholder: '图标（可选，输入 URL 或描述）', text: this.stockIcon })
          .onChange(value => this.stockIcon = value)
          .margin({ bottom: 12 });

        Button('保存股票信息')
          .width('100%')
          .height(40)
          .type(ButtonType.Capsule)
          .backgroundColor('#0057FF')
          .fontColor(Color.White)
          .onClick(() => this.handleUpsertStock());
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12)
      .margin({ bottom: 16 });

      Column() {
        this.subSectionTitle('已维护股票');
        if (this.store.stocks.length === 0) {
          Text('暂无记录')
            .fontColor('#909090')
            .fontSize(14)
            .margin({ top: 8 });
        } else {
          ForEach(this.store.stocks, (item: StockInfo) => {
            Column() {
              Text(`${item.code} · ${item.name}`)
                .fontSize(16)
                .fontColor('#202020');
              if (item.icon) {
                Text(`图标：${item.icon}`)
                  .fontSize(14)
                  .fontColor('#606060')
                  .margin({ top: 4 });
              }
            }
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 0.5 }, color: '#EFEFEF' });
          }, (item: StockInfo) => item.code);
        }
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12);
    }
    .margin({ bottom: 24 });
  }

  private renderInvestmentSection(): void {
    Column() {
      this.sectionTitle($r('app.string.section_investment_header'));
      this.sectionSubtitle($r('app.string.section_investment_subtitle'));

      Column() {
        if (this.store.stocks.length === 0) {
          Text('请先维护股票信息。')
            .fontColor('#D93025')
            .fontSize(14)
            .margin({ bottom: 12 });
        } else {
          Scroll(ScrollDirection.Horizontal) {
            Row() {
              ForEach(this.store.stocks, (stock: StockInfo) => {
                Button(`${stock.code}`)
                  .type(ButtonType.Capsule)
                  .fontSize(14)
                  .fontColor(this.investmentStockCode === stock.code ? Color.White : '#202020')
                  .backgroundColor(this.investmentStockCode === stock.code ? '#0057FF' : '#E4E9F5')
                  .margin({ right: 8 })
                  .onClick(() => this.investmentStockCode = stock.code);
              }, (stock: StockInfo) => stock.code);
            }
            .width('100%');
          }
          .margin({ bottom: 12 })
          .height(44);
          this.ensureInvestmentStockCode();
        }

        Row() {
          this.directionToggle('买入', InvestmentDirection.BUY);
          this.directionToggle('卖出', InvestmentDirection.SELL);
        }
        .margin({ bottom: 12 })
        .justifyContent(FlexAlign.Start);

        TextInput({ placeholder: '购买份额（整数）', text: this.investmentQuantity })
          .type(InputType.Number)
          .onChange(value => this.investmentQuantity = value)
          .margin({ bottom: 8 });

        TextInput({ placeholder: '单价（两位小数）', text: this.investmentPrice })
          .type(InputType.Decimal)
          .onChange(value => this.investmentPrice = value)
          .margin({ bottom: 8 });

        Row() {
          ForEach(SUPPORTED_CURRENCIES, (currency: CurrencyCode) => {
            Button(currency)
              .type(ButtonType.Capsule)
              .fontSize(14)
              .fontColor(this.investmentCurrency === currency ? Color.White : '#202020')
              .backgroundColor(this.investmentCurrency === currency ? '#0D8A1E' : '#E4E9F5')
              .margin({ right: 8 })
              .onClick(() => this.investmentCurrency = currency);
          });
        }
        .margin({ bottom: 12 });

        TextInput({ placeholder: '备注（可选）', text: this.investmentNote })
          .onChange(value => this.investmentNote = value)
          .margin({ bottom: 12 });

        Button('记录投资')
          .width('100%')
          .height(40)
          .type(ButtonType.Capsule)
          .backgroundColor('#0D8A1E')
          .fontColor(Color.White)
          .onClick(() => this.handleRecordInvestment());
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12)
      .margin({ bottom: 16 });

      Column() {
        this.subSectionTitle('最新投资记录');
        if (this.store.investments.length === 0) {
          Text('暂无记录')
            .fontColor('#909090')
            .fontSize(14)
            .margin({ top: 8 });
        } else {
          ForEach(this.store.investments, (item: InvestmentRecord) => {
            Column() {
              Text(`${this.directionLabel(item.direction)} ${item.stockCode} · ${item.quantity} @ ${item.unitPrice.toFixed(2)} ${item.currency}`)
                .fontSize(15)
                .fontColor('#202020');
              Text(`金额：${item.amount.toFixed(2)} ${item.currency}`)
                .fontColor(item.amount >= 0 ? '#0D8A1E' : '#D93025')
                .fontSize(14)
                .margin({ top: 4 });
              Text(`时间：${this.formatDate(item.createdAt)}`)
                .fontColor('#909090')
                .fontSize(12)
                .margin({ top: 4 });
              if (item.note) {
                Text(`备注：${item.note}`)
                  .fontSize(12)
                  .fontColor('#606060')
                  .margin({ top: 4 });
              }
            }
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 0.5 }, color: '#EFEFEF' });
          }, (item: InvestmentRecord) => item.id);
        }
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12);
    }
    .margin({ bottom: 24 });
  }

  private renderBalanceSection(): void {
    Column() {
      this.sectionTitle($r('app.string.section_balance_header'));
      this.sectionSubtitle($r('app.string.section_balance_subtitle'));

        Column() {
          TextInput({ placeholder: '金额（正数存入，负数取出）', text: this.adjustmentAmount })
            .type(InputType.Decimal)
            .onChange(value => this.adjustmentAmount = value)
            .margin({ bottom: 8 });

          Row() {
            ForEach(SUPPORTED_CURRENCIES, (currency: CurrencyCode) => {
              Button(currency)
                .type(ButtonType.Capsule)
                .fontSize(14)
                .fontColor(this.adjustmentCurrency === currency ? Color.White : '#202020')
                .backgroundColor(this.adjustmentCurrency === currency ? '#FF8C00' : '#E4E9F5')
                .margin({ right: 8 })
                .onClick(() => this.adjustmentCurrency = currency);
            });
          }
          .margin({ bottom: 12 });

        TextInput({ placeholder: '备注（必填）', text: this.adjustmentNote })
          .onChange(value => this.adjustmentNote = value)
          .margin({ bottom: 12 });

        Button('调整账户余额')
          .width('100%')
          .height(40)
          .type(ButtonType.Capsule)
          .backgroundColor('#FF8C00')
          .fontColor(Color.White)
          .onClick(() => this.handleManualAdjustment());
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12)
      .margin({ bottom: 16 });

      Column() {
        this.subSectionTitle('账户余额');
        ForEach(SUPPORTED_CURRENCIES, (currency: CurrencyCode) => {
          const balance: number = this.store.accountBalances[currency] ?? 0;
          Row() {
            Text(currency)
              .fontSize(15)
              .fontColor('#202020');
            Blank();
            Text(balance.toFixed(2))
              .fontSize(15)
              .fontColor(balance >= 0 ? '#202020' : '#D93025');
          }
          .margin({ top: 12 });
        });
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12)
      .margin({ bottom: 16 });

      Column() {
        this.subSectionTitle('股票持仓');
        if (this.store.holdings.length === 0) {
          Text('暂无记录')
            .fontColor('#909090')
            .fontSize(14)
            .margin({ top: 8 });
        } else {
          ForEach(this.store.holdings, (holding: StockHolding) => {
            Column() {
              Text(`${holding.stockCode} · 持仓：${holding.quantity}`)
                .fontSize(15)
                .fontColor('#202020');
              Text(`平均成本：${holding.averageCost.toFixed(2)} CNY`)
                .fontSize(13)
                .fontColor('#606060')
                .margin({ top: 4 });
            }
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 0.5 }, color: '#EFEFEF' });
          }, (item: StockHolding) => item.stockCode);
        }
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12);
    }
    .margin({ bottom: 24 });
  }

  private renderExchangeSection(): void {
    Column() {
      this.sectionTitle($r('app.string.section_exchange_header'));
      this.sectionSubtitle($r('app.string.section_exchange_subtitle'));

        Column() {
          Row() {
            ForEach(SUPPORTED_CURRENCIES, (currency: CurrencyCode) => {
              Button(`基准 ${currency}`)
                .type(ButtonType.Capsule)
                .fontSize(13)
                .fontColor(this.exchangeBase === currency ? Color.White : '#202020')
                .backgroundColor(this.exchangeBase === currency ? '#0057FF' : '#E4E9F5')
                .margin({ right: 8, bottom: 8 })
                .onClick(() => this.exchangeBase = currency);
            });
          }

          Row() {
            ForEach(SUPPORTED_CURRENCIES, (currency: CurrencyCode) => {
              Button(`兑换 ${currency}`)
                .type(ButtonType.Capsule)
                .fontSize(13)
                .fontColor(this.exchangeQuote === currency ? Color.White : '#202020')
                .backgroundColor(this.exchangeQuote === currency ? '#0057FF' : '#E4E9F5')
                .margin({ right: 8, bottom: 8 })
                .onClick(() => this.exchangeQuote = currency);
            });
          }

        TextInput({ placeholder: '汇率（正数）', text: this.exchangeRate })
          .type(InputType.Decimal)
          .onChange(value => this.exchangeRate = value)
          .margin({ bottom: 12 });

        Button('更新汇率')
          .width('100%')
          .height(40)
          .type(ButtonType.Capsule)
          .backgroundColor('#0057FF')
          .fontColor(Color.White)
          .onClick(() => this.handleUpdateExchangeRate());
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12)
      .margin({ bottom: 16 });

      Column() {
        this.subSectionTitle('当前汇率');
        if (this.store.exchangeRates.length === 0) {
          Text('暂无汇率数据')
            .fontSize(14)
            .fontColor('#909090')
            .margin({ top: 8 });
        } else {
          ForEach(this.store.exchangeRates, (rate: ExchangeRate) => {
            Column() {
              Text(`${rate.base} -> ${rate.quote} : ${rate.rate.toFixed(5)}`)
                .fontSize(14)
                .fontColor('#202020');
              Text(`更新时间：${this.formatDate(rate.timestamp)}`)
                .fontSize(12)
                .fontColor('#909090')
                .margin({ top: 4 });
            }
            .padding({ top: 12, bottom: 12 })
            .border({ width: { bottom: 0.5 }, color: '#EFEFEF' });
          }, (item: ExchangeRate) => `${item.base}-${item.quote}`);
        }
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12);
    }
    .margin({ bottom: 24 });
  }

  private renderSummary(): void {
    Column() {
      this.sectionTitle($r('app.string.section_summary_header'));
      this.sectionSubtitle($r('app.string.section_summary_subtitle'));

      Column() {
        Text('系统严格遵循以下规则：')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#202020')
          .margin({ bottom: 12 });
        Text('· 股票信息需先维护后使用。')
          .fontSize(13)
          .fontColor('#606060')
          .margin({ bottom: 4 });
        Text('· 购买份额必须为整数且在规定区间内。')
          .fontSize(13)
          .fontColor('#606060')
          .margin({ bottom: 4 });
        Text('· 单价需保留两位小数。')
          .fontSize(13)
          .fontColor('#606060')
          .margin({ bottom: 4 });
        Text('· 系统自动计算金额并更新余额、持仓。')
          .fontSize(13)
          .fontColor('#606060')
          .margin({ bottom: 4 });
        Text('· 支持人民币与美元的汇率维护与换算。')
          .fontSize(13)
          .fontColor('#606060');
      }
      .backgroundColor(Color.White)
      .padding(16)
      .borderRadius(12);
    }
  }

  private sectionTitle(title: Resource): void {
    Text(title)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor('#202020')
      .margin({ bottom: 8 });
  }

  private sectionSubtitle(subtitle: Resource): void {
    Text(subtitle)
      .fontSize(13)
      .fontColor('#606060')
      .margin({ bottom: 16 });
  }

  private subSectionTitle(title: string): void {
    Text(title)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor('#202020');
  }

  private ensureInvestmentStockCode(): void {
    if (!this.investmentStockCode && this.store.stocks.length > 0) {
      this.investmentStockCode = this.store.stocks[0].code;
    }
  }

  private directionToggle(label: string, direction: InvestmentDirection): void {
    const isActive: boolean = this.investmentDirection === direction;
    Button(label)
      .type(ButtonType.Capsule)
      .fontSize(14)
      .fontColor(isActive ? Color.White : '#202020')
      .backgroundColor(isActive ? '#0D8A1E' : '#E4E9F5')
      .margin({ right: 12 })
      .onClick(() => this.investmentDirection = direction);
  }

  private handleUpsertStock(): void {
    this.clearMessages();
    try {
      this.store.upsertStock({
        code: this.stockCode,
        name: this.stockName,
        icon: this.stockIcon
      });
      this.feedbackMessage = '股票信息已保存。';
      this.stockCode = '';
      this.stockName = '';
      this.stockIcon = '';
      this.refreshInvestmentStockCode();
    } catch (error) {
      this.errorMessage = this.safeMessage(error);
    }
  }

    private handleRecordInvestment(): void {
      this.clearMessages();

      const quantityInput: string = this.investmentQuantity.trim();
      const quantity: number = Number(quantityInput);
      if (!quantityInput || !Number.isInteger(quantity)) {
        this.errorMessage = '购买份额必须为整数。';
        return;
      }

      const priceInput: string = this.investmentPrice.trim();
      const unitPrice: number = Number(priceInput);
      if (!priceInput || isNaN(unitPrice)) {
        this.errorMessage = '单价必须为数字。';
        return;
      }

      try {
        this.store.recordInvestment({
          stockCode: this.investmentStockCode,
          direction: this.investmentDirection,
          quantity,
          unitPrice,
          currency: this.investmentCurrency,
          note: this.investmentNote
        });
        this.feedbackMessage = '投资记录已创建。';
        this.investmentQuantity = '';
        this.investmentPrice = '';
        this.investmentNote = '';
      } catch (error) {
        this.errorMessage = this.safeMessage(error);
      }
    }

  private handleManualAdjustment(): void {
    this.clearMessages();
    const amountInput: string = this.adjustmentAmount.trim();
    const amount: number = Number(amountInput);
    if (!amountInput || isNaN(amount)) {
      this.errorMessage = '金额必须为数字。';
      return;
    }
    if (!this.adjustmentNote.trim()) {
      this.errorMessage = '备注不能为空，用于说明手动操作。';
      return;
    }

    try {
      this.store.recordManualAdjustment(amount, this.adjustmentCurrency, this.adjustmentNote);
      this.feedbackMessage = '账户余额已调整。';
      this.adjustmentAmount = '';
      this.adjustmentNote = '';
    } catch (error) {
      this.errorMessage = this.safeMessage(error);
    }
  }

  private handleUpdateExchangeRate(): void {
    this.clearMessages();
    if (this.exchangeBase === this.exchangeQuote) {
      this.errorMessage = '汇率的币种不能相同。';
      return;
    }

    const rateInput: string = this.exchangeRate.trim();
    const rate: number = Number(rateInput);
    if (!rateInput || isNaN(rate) || rate <= 0) {
      this.errorMessage = '请输入正确的正数汇率。';
      return;
    }

    try {
      this.store.setExchangeRate(this.exchangeBase, this.exchangeQuote, rate);
      this.feedbackMessage = '汇率已更新。';
      this.exchangeRate = '';
    } catch (error) {
      this.errorMessage = this.safeMessage(error);
    }
  }

  private refreshInvestmentStockCode(): void {
    if (!this.investmentStockCode && this.store.stocks.length > 0) {
      this.investmentStockCode = this.store.stocks[0].code;
    }
  }

  private directionLabel(direction: InvestmentDirection): string {
    return direction === InvestmentDirection.BUY ? '买入' : '卖出';
  }

  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${this.pad(date.getMonth() + 1)}-${this.pad(date.getDate())} ${this.pad(date.getHours())}:${this.pad(date.getMinutes())}:${this.pad(date.getSeconds())}`;
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private clearMessages(): void {
    this.feedbackMessage = '';
    this.errorMessage = '';
  }

  private safeMessage(error: any): string {
    if (error && typeof error.message === 'string') {
      return error.message;
    }
    return '操作失败，请检查输入。';
  }
}
