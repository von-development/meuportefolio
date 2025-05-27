import csv
import pyodbc
from datetime import datetime
import os

def connect_to_db():
    """Conecta ao banco de dados SQL Server"""
    conn = pyodbc.connect(
        'DRIVER={SQL Server};'
        'SERVER=localhost,1433;'
        'DATABASE=meuportefolio;'
        'UID=sa;'
        'PWD=meuportefolio!23;'
        'TrustServerCertificate=yes;'
    )
    return conn

def clean_numeric(value):
    """Limpa valores numéricos"""
    if isinstance(value, (int, float)):
        return float(value)
    
    if isinstance(value, str):
        # Remove aspas, vírgulas e espaços
        value = value.strip('"').replace(',', '').strip()
        
        # Se for vazio, retorna 0
        if not value:
            return 0.0
            
        # Converte K/M/B para valores numéricos
        multiplier = 1.0
        if 'K' in value:
            value = value.replace('K', '')
            multiplier = 1000.0
        elif 'M' in value:
            value = value.replace('M', '')
            multiplier = 1000000.0
        elif 'B' in value:
            value = value.replace('B', '')
            multiplier = 1000000000.0
            
        # Remove o símbolo de porcentagem
        if '%' in value:
            value = value.replace('%', '')
            
        try:
            return float(value) * multiplier
        except ValueError:
            return 0.0
    
    return 0.0

def get_or_create_asset(cursor, asset_info):
    """Cria ou obtém um ativo, retornando seu ID"""
    # Primeiro tenta obter o ativo existente
    cursor.execute("""
        SELECT AssetID FROM portfolio.Assets WHERE Symbol = ?
    """, (asset_info['symbol'],))
    
    row = cursor.fetchone()
    if row:
        asset_id = row[0]
    else:
        # Se não existe, cria um novo
        cursor.execute("""
            DECLARE @NewAssetID INT;
            
            INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares)
            OUTPUT INSERTED.AssetID
            VALUES (?, ?, ?, 0.00, 0, ?);
        """, (
            asset_info['symbol'],
            asset_info['name'],
            asset_info['type'],
            asset_info['shares']
        ))
        
        row = cursor.fetchone()
        asset_id = row[0]
        cursor.commit()
    
    return asset_id

def import_asset_data(cursor, asset_info, csv_path):
    """Importa dados de um ativo específico"""
    try:
        # Cria/Atualiza o ativo
        asset_id = get_or_create_asset(cursor, asset_info)
        print(f"{asset_info['name']} encontrado/criado com ID: {asset_id}")
        
        # Lê o arquivo CSV
        with open(csv_path, 'r') as file:
            # Pula o cabeçalho
            next(file)
            # Conta as linhas restantes
            total_rows = sum(1 for line in file)
            
        print(f"Arquivo CSV lido com sucesso. Total de registros: {total_rows}")
        
        # Processa cada linha
        inserted = 0
        skipped = 0
        
        with open(csv_path, 'r') as file:
            # Pula o cabeçalho
            next(file)
            
            for idx, line in enumerate(file, 1):
                try:
                    # Remove aspas e divide a linha
                    fields = line.strip().replace('"', '').split(',')
                    
                    # Extrai os campos
                    date_str = fields[0]
                    price = clean_numeric(fields[1])
                    open_price = clean_numeric(fields[2])
                    high = clean_numeric(fields[3])
                    low = clean_numeric(fields[4])
                    volume = clean_numeric(fields[5])
                    
                    # Converte a data
                    date = datetime.strptime(date_str, '%m/%d/%Y')
                    
                    # Debug
                    print(f"\nProcessando linha {idx}:")
                    print(f"Data: {date}")
                    print(f"Preço: {price}")
                    print(f"Open: {open_price}")
                    print(f"High: {high}")
                    print(f"Low: {low}")
                    print(f"Volume: {volume}")
                    
                    # Verifica se o preço já existe
                    cursor.execute("""
                        IF NOT EXISTS (
                            SELECT 1 
                            FROM portfolio.AssetPrices 
                            WHERE AssetID = ? AND AsOf = ?
                        )
                        BEGIN
                            INSERT INTO portfolio.AssetPrices (
                                AssetID,
                                Price,
                                AsOf,
                                OpenPrice,
                                HighPrice,
                                LowPrice,
                                Volume
                            )
                            VALUES (?, ?, ?, ?, ?, ?, ?);
                            
                            UPDATE portfolio.Assets 
                            SET Price = ?,
                                Volume = ?,
                                LastUpdated = GETDATE()
                            WHERE AssetID = ?;
                        END
                    """, (
                        asset_id, date,  # Para o IF NOT EXISTS
                        asset_id, price, date, open_price, high, low, volume,  # Para o INSERT
                        price, volume, asset_id  # Para o UPDATE
                    ))
                    cursor.commit()
                    
                    inserted += 1
                    print(f"Linha {idx} importada com sucesso!")
                    
                    # Feedback a cada 10 registros
                    if inserted % 10 == 0 and inserted > 0:
                        print(f"\nProcessados {inserted} de {total_rows} registros...")
                
                except Exception as row_error:
                    print(f"Erro ao processar linha {idx}: {str(row_error)}")
                    skipped += 1
                    continue
        
        print(f"\nImportação de {asset_info['name']} concluída!")
        print(f"Total de registros processados: {total_rows}")
        print(f"Registros inseridos com sucesso: {inserted}")
        print(f"Registros com erro: {skipped}")
        
    except Exception as e:
        print(f"Erro durante a importação de {asset_info['name']}: {str(e)}")
        raise

def main():
    """Função principal"""
    try:
        # Conecta ao banco de dados
        conn = connect_to_db()
        cursor = conn.cursor()
        
        # Define os ativos a serem importados
        assets = [
            {
                'symbol': 'BTC',
                'name': 'Bitcoin',
                'type': 'Cryptocurrency',
                'file': 'db/csv/BTC_0103-0527.csv',
                'shares': 1000000000
            },
            {
                'symbol': 'ETH',
                'name': 'Ethereum',
                'type': 'Cryptocurrency',
                'file': 'db/csv/ETH_0103-0527.csv',
                'shares': 1000000000
            },
            {
                'symbol': 'SOL',
                'name': 'Solana',
                'type': 'Cryptocurrency',
                'file': 'db/csv/SOL_0103-0527.csv',
                'shares': 1000000000
            },
            {
                'symbol': 'AAPL',
                'name': 'Apple Inc.',
                'type': 'Company',
                'file': 'db/csv/APPL_0103-0527.csv',
                'shares': 1000000000
            },
            {
                'symbol': 'NVDA',
                'name': 'NVIDIA Corporation',
                'type': 'Company',
                'file': 'db/csv/NVDIA_0103-0527.csv',
                'shares': 1000000000
            },
            {
                'symbol': 'META',
                'name': 'Meta Platforms Inc.',
                'type': 'Company',
                'file': 'db/csv/META_0103-0527.csv',
                'shares': 1000000000
            }
        ]
        
        # Importa cada ativo
        for asset in assets:
            if os.path.exists(asset['file']):
                print(f"\nIniciando importação do arquivo: {asset['file']}")
                import_asset_data(cursor, asset, asset['file'])
            else:
                print(f"Arquivo não encontrado: {asset['file']}")
        
        # Fecha a conexão
        cursor.close()
        conn.close()
        print("\nConexão com o banco fechada.")
        
    except Exception as e:
        print(f"Erro durante a execução: {str(e)}")
        raise

if __name__ == '__main__':
    main() 