#![no_std]
#![no_main]

extern crate alloc;

mod data;
mod http;
mod otlp;
mod otlp_json;
mod platform;
mod proto;
mod runtime;
mod scheme;
mod server;
mod stats;
mod storage;
mod trace_forest;
mod validation;
