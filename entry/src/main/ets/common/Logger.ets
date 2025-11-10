const DEFAULT_TAG: string = 'StockLedger';

export default class Logger {
  static info(message: string, tag: string = DEFAULT_TAG): void {
    console.info(`[${tag}] ${message}`);
  }

  static warn(message: string, tag: string = DEFAULT_TAG): void {
    console.warn(`[${tag}] ${message}`);
  }

  static error(message: string, tag: string = DEFAULT_TAG): void {
    console.error(`[${tag}] ${message}`);
  }
}
