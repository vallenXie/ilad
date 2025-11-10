export type CurrencyCode = 'CNY' | 'USD';

export interface ExchangeRate {
  base: CurrencyCode;
  quote: CurrencyCode;
  rate: number;
  timestamp: Date;
}

export interface StockInfo {
  code: string;
  name: string;
  icon?: string;
}

export enum InvestmentDirection {
  BUY = -1,
  SELL = 1
}

export interface InvestmentRecord {
  id: string;
  stockCode: string;
  direction: InvestmentDirection;
  quantity: number;
  unitPrice: number;
  amount: number;
  currency: CurrencyCode;
  createdAt: Date;
  note?: string;
}

export interface StockHolding {
  stockCode: string;
  quantity: number;
  averageCost: number;
}

export interface ManualBalanceAdjustment {
  id: string;
  amount: number;
  currency: CurrencyCode;
  note: string;
  createdAt: Date;
}
