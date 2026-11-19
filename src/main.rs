use clap::Parser;
use std::env;
use std::fs;
use std::io;
use std::process;

#[derive(Parser)]
#[command(version, about, long_about = None)]
struct Cli {
    file: String,
}

fn main() -> Result<(), io::Error> {
    let cli = Cli::parse();

    let _noon_path = match env::var("NOON_PATH") {
        Ok(val) => val,
        Err(_) => {
            eprintln!("Error: NOON_PATH must be set.");
            process::exit(1);
        }
    };

    let source = fs::read_to_string(cli.file)?;
    noon::lexer::lex(source);
    Ok(())
}
