CREATE DATABASE IF NOT EXISTS hft_dashboard;

CREATE TABLE IF NOT EXISTS hft_dashboard.historical_trades
(
    symbol     String          CODEC(ZSTD(3)),
    side       Int8,
    price      Decimal64(8)    CODEC(ZSTD(3)),
    amount     Decimal64(8)    CODEC(ZSTD(3)),
    timestamp  DateTime64(6)   CODEC(DoubleDelta, ZSTD(1)),
    order_id   String          CODEC(ZSTD(3)),
    trader_id  UInt32          CODEC(ZSTD(1))
    )
    ENGINE = MergeTree()
    ORDER BY (symbol, timestamp)
    PARTITION BY toYYYYMM(timestamp)
    TTL timestamp + INTERVAL 2 HOUR DELETE;

CREATE TABLE IF NOT EXISTS hft_dashboard.market_ohlc
(
    symbol      String        CODEC(ZSTD(3)),
    candle_time DateTime64(6) CODEC(DoubleDelta, ZSTD(1)),
    open        Decimal64(8)  CODEC(ZSTD(3)),
    high        Decimal64(8)  CODEC(ZSTD(3)),
    low         Decimal64(8)  CODEC(ZSTD(3)),
    close       Decimal64(8)  CODEC(ZSTD(3)),
    volume      Decimal64(8)  CODEC(ZSTD(3))
    )
    ENGINE = ReplacingMergeTree()
    ORDER BY (symbol, candle_time)
    PARTITION BY toYYYYMM(candle_time)
    TTL toDateTime(candle_time) + INTERVAL 90 DAY DELETE;

-- Create inserter_user with permission to write to both tables
CREATE USER IF NOT EXISTS inserter_user
    IDENTIFIED WITH plaintext_password BY 'inserter_pass';

GRANT INSERT ON hft_dashboard.historical_trades TO inserter_user;
GRANT INSERT ON hft_dashboard.market_ohlc TO inserter_user;

-- Also grant SELECT so the Rust app can read back for the OHLCV endpoint
GRANT SELECT ON hft_dashboard.* TO inserter_user;