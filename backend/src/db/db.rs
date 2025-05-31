use tiberius::{Client, Config, AuthMethod};
use tokio::net::TcpStream;
use tokio_util::compat::TokioAsyncWriteCompatExt;
use anyhow::Result;
use std::env;

pub async fn get_db_client() -> Result<Client<tokio_util::compat::Compat<TcpStream>>> {
    let mut config = Config::new();
    
    // Get database configuration from environment variables with fallbacks
    let db_host = env::var("DATABASE_HOST").unwrap_or_else(|_| "mednat.ieeta.pt".to_string());
    let db_port: u16 = env::var("DATABASE_PORT")
        .unwrap_or_else(|_| "8101".to_string())
        .parse()
        .unwrap_or(8101);
    let db_user = env::var("DATABASE_USER").unwrap_or_else(|_| "p6g4".to_string());
    let db_password = env::var("DATABASE_PASSWORD").unwrap_or_else(|_| "VictorMaria123".to_string());
    let db_name = env::var("DATABASE_NAME").unwrap_or_else(|_| "p6g4".to_string());
    let db_instance = env::var("DATABASE_INSTANCE").unwrap_or_else(|_| "SQLSERVER".to_string());
    
    // Configure the connection for SQL Server with instance
    let full_host = if db_instance.is_empty() {
        db_host
    } else {
        format!("{}\\{}", db_host, db_instance)
    };
    
    config.host(&full_host);
    config.port(db_port);
    config.authentication(AuthMethod::sql_server(&db_user, &db_password));
    config.trust_cert();
    config.database(&db_name);
    
    // For debugging - log connection details (without password)
    println!("Connecting to SQL Server:");
    println!("  Host: {}", full_host);
    println!("  Port: {}", db_port);
    println!("  Database: {}", db_name);
    println!("  User: {}", db_user);

    let tcp = TcpStream::connect(config.get_addr()).await?;
    let tcp = tcp.compat_write();
    let client = Client::connect(config, tcp).await?;
    
    Ok(client)
} 