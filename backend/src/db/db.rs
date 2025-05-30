use tiberius::{Client, Config, AuthMethod};
use tokio::net::TcpStream;
use tokio_util::compat::TokioAsyncWriteCompatExt;
use anyhow::Result;

pub async fn get_db_client() -> Result<Client<tokio_util::compat::Compat<TcpStream>>> {
    let mut config = Config::new();
    config.host("db");
    config.port(1433);
    config.authentication(AuthMethod::sql_server("sa", "meuportefolio!23"));
    config.trust_cert();
    config.database("meuportefolio");

    let tcp = TcpStream::connect(config.get_addr()).await?;
    let tcp = tcp.compat_write();
    let client = Client::connect(config, tcp).await?;
    
    Ok(client)
} 