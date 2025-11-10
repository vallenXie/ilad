import { CurrencyCode, ExchangeRate, InvestmentDirection, InvestmentRecord, ManualBalanceAdjustment, StockHolding, StockInfo } from '../model/StockModels';
import Logger from '../common/Logger';

const MIN_QUANTITY: number = -999999999;
const MAX_QUANTITY: number = 999999999;

const DEFAULT_EXCHANGE_RATES: Array<ExchangeRate> = [
  {
    base: 'CNY',
    quote: 'USD',
    rate: 0.137,
    timestamp: new Date()
  },
  {
    base: 'USD',
    quote: 'CNY',
    rate: 7.30,
    timestamp: new Date()
  }
];

@Observed
export class StockStore {
  private static instance?: StockStore;

  stocks: Array<StockInfo> = [];
  investments: Array<InvestmentRecord> = [];
  holdings: Array<StockHolding> = [];
  manualAdjustments: Array<ManualBalanceAdjustment> = [];
  accountBalances: Record<CurrencyCode, number> = {
    CNY: 0,
    USD: 0
  };
  exchangeRates: Array<ExchangeRate> = [...DEFAULT_EXCHANGE_RATES];

  private constructor() {
    Logger.info('StockStore initialized');
  }

  static getInstance(): StockStore {
    if (!StockStore.instance) {
      StockStore.instance = new StockStore();
    }
    return StockStore.instance;
  }

  getStockByCode(code: string): StockInfo | undefined {
    return this.stocks.find(stock => stock.code === code);
  }

  upsertStock(stock: StockInfo): void {
    const trimmedCode: string = stock.code.trim().toUpperCase();
    const trimmedName: string = stock.name.trim();
    if (!trimmedCode || !trimmedName) {
      throw new Error('股票代码和名称不能为空。');
    }

    const existingIndex: number = this.stocks.findIndex(item => item.code === trimmedCode);
    if (existingIndex >= 0) {
      const updatedStock: StockInfo = {
        code: trimmedCode,
        name: trimmedName,
        icon: stock.icon?.trim()
      };
      const updatedStocks: Array<StockInfo> = [...this.stocks];
      updatedStocks[existingIndex] = updatedStock;
      this.stocks = updatedStocks;
      Logger.info(`更新股票信息：${trimmedCode}`);
      return;
    }

    const newStock: StockInfo = {
      code: trimmedCode,
      name: trimmedName,
      icon: stock.icon?.trim()
    };
    this.stocks = [...this.stocks, newStock];
    this.holdings = [...this.holdings, { stockCode: trimmedCode, quantity: 0, averageCost: 0 }];
    Logger.info(`新增股票信息：${trimmedCode}`);
  }

  recordManualAdjustment(amount: number, currency: CurrencyCode, note: string): void {
    if (!this.accountBalances[currency]) {
      this.accountBalances = { ...this.accountBalances, [currency]: 0 };
    }

    const sanitizedAmount: number = this.roundToCurrency(amount);
    this.accountBalances = {
      ...this.accountBalances,
      [currency]: this.roundToCurrency(this.accountBalances[currency] + sanitizedAmount)
    };

    const adjustment: ManualBalanceAdjustment = {
      id: this.generateId('ADJ'),
      amount: sanitizedAmount,
      currency,
      note: note.trim(),
      createdAt: new Date()
    };
    this.manualAdjustments = [adjustment, ...this.manualAdjustments];
    Logger.info(`手动调整余额：${sanitizedAmount} ${currency}`);
  }

  recordInvestment(params: {
    stockCode: string;
    direction: InvestmentDirection;
    quantity: number;
    unitPrice: number;
    currency: CurrencyCode;
    note?: string;
  }): void {
    const stock: StockInfo | undefined = this.getStockByCode(params.stockCode);
    if (!stock) {
      throw new Error('股票不存在，请先维护股票信息。');
    }

    const quantity: number = params.quantity;
    if (!Number.isInteger(quantity)) {
      throw new Error('购买份额必须为整数。');
    }
    if (quantity < MIN_QUANTITY || quantity > MAX_QUANTITY) {
      throw new Error(`购买份额需在 ${MIN_QUANTITY} 与 ${MAX_QUANTITY} 之间。`);
    }

    const unitPrice: number = params.unitPrice;
    if (!this.isValidCurrencyAmount(unitPrice)) {
      throw new Error('单价需精确到两位小数。');
    }

    const direction: InvestmentDirection = params.direction;
    if (direction !== InvestmentDirection.BUY && direction !== InvestmentDirection.SELL) {
      throw new Error('投资方向必须为“买入”或“卖出”。');
    }

    const amount: number = this.roundToCurrency(direction * quantity * unitPrice);
    const record: InvestmentRecord = {
      id: this.generateId('INV'),
      stockCode: stock.code,
      direction,
      quantity,
      unitPrice: this.roundToCurrency(unitPrice),
      amount,
      currency: params.currency,
      createdAt: new Date(),
      note: params.note?.trim()
    };

    this.investments = [record, ...this.investments];
    this.updateAccountBalance(record);
    this.updateHolding(record);
    Logger.info(`记录投资：${stock.code} 金额 ${amount} ${params.currency}`);
  }

  private updateAccountBalance(record: InvestmentRecord): void {
    const currentBalance: number = this.accountBalances[record.currency] ?? 0;
    const newBalance: number = this.roundToCurrency(currentBalance + record.amount);
    this.accountBalances = {
      ...this.accountBalances,
      [record.currency]: newBalance
    };
  }

  private updateHolding(record: InvestmentRecord): void {
    const idx: number = this.holdings.findIndex(item => item.stockCode === record.stockCode);
    if (idx < 0) {
      this.holdings = [
        ...this.holdings,
        {
          stockCode: record.stockCode,
          quantity: record.quantity * (record.direction === InvestmentDirection.BUY ? 1 : -1),
          averageCost: record.unitPrice
        }
      ];
      return;
    }

    const holding: StockHolding = this.holdings[idx];
    let newQuantity: number = holding.quantity;
    let newAverageCost: number = holding.averageCost;

    if (record.direction === InvestmentDirection.BUY) {
      const totalCost: number = this.roundToCurrency(holding.averageCost * holding.quantity + record.unitPrice * record.quantity);
      newQuantity = holding.quantity + record.quantity;
      newAverageCost = newQuantity !== 0 ? this.roundToCurrency(totalCost / newQuantity) : 0;
    } else {
      newQuantity = holding.quantity - record.quantity;
      if (newQuantity < 0) {
        Logger.warn(`卖出份额超过持仓，允许负持仓记录：${record.stockCode}`);
      }
    }

    const updatedHolding: StockHolding = {
      stockCode: holding.stockCode,
      quantity: newQuantity,
      averageCost: newAverageCost
    };

    const updatedHoldings: Array<StockHolding> = [...this.holdings];
    updatedHoldings[idx] = updatedHolding;
    this.holdings = updatedHoldings;
  }

  setExchangeRate(base: CurrencyCode, quote: CurrencyCode, rate: number): void {
    if (base === quote) {
      throw new Error('汇率的币种不能相同。');
    }
    if (rate <= 0) {
      throw new Error('汇率必须为正数。');
    }
    const sanitizedRate: number = this.roundToExchangeRate(rate);
    const timestamp: Date = new Date();

    const matcher = (item: ExchangeRate) => item.base === base && item.quote === quote;
    if (this.exchangeRates.some(matcher)) {
      this.exchangeRates = this.exchangeRates.map(rateItem => matcher(rateItem) ? { ...rateItem, rate: sanitizedRate, timestamp } : rateItem);
    } else {
      this.exchangeRates = [...this.exchangeRates, { base, quote, rate: sanitizedRate, timestamp }];
    }

    const inverseMatcher = (item: ExchangeRate) => item.base === quote && item.quote === base;
    const inverseRate: number = this.roundToExchangeRate(1 / sanitizedRate);
    if (this.exchangeRates.some(inverseMatcher)) {
      this.exchangeRates = this.exchangeRates.map(rateItem => inverseMatcher(rateItem) ? { ...rateItem, rate: inverseRate, timestamp } : rateItem);
    } else {
      this.exchangeRates = [...this.exchangeRates, { base: quote, quote: base, rate: inverseRate, timestamp }];
    }
  }

  findExchangeRate(base: CurrencyCode, quote: CurrencyCode): ExchangeRate | undefined {
    return this.exchangeRates.find(rate => rate.base === base && rate.quote === quote);
  }

  convert(amount: number, from: CurrencyCode, to: CurrencyCode): number {
    if (from === to) {
      return this.roundToCurrency(amount);
    }
    const rate: ExchangeRate | undefined = this.findExchangeRate(from, to);
    if (!rate) {
      throw new Error(`未找到从 ${from} 到 ${to} 的汇率。`);
    }
    return this.roundToCurrency(amount * rate.rate);
  }

  private roundToCurrency(value: number): number {
    return Math.round(value * 100) / 100;
  }

  private roundToExchangeRate(value: number): number {
    return Math.round(value * 100000) / 100000;
  }

  private isValidCurrencyAmount(value: number): boolean {
    return Number.isFinite(value) && Number.isInteger(Math.round(value * 100));
  }

  private generateId(prefix: string): string {
    return `${prefix}_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }
}

export default StockStore;
