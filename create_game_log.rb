require 'json'
require 'pg'
require_relative 'processor'

database = JSON.parse(File.read('./database_local.json'))

begin
    Processor.processing()

	conn = PG.connect :dbname   => database['database'], 
                      :user     => database['username'], 
                      :password => database['password'], 
                      :host     => database['dataserver']

    conn.exec "DROP TABLE IF EXISTS game_log"
    conn.exec "DROP SEQUENCE IF EXISTS serial"

    conn.exec "CREATE SEQUENCE serial"
    conn.exec "CREATE TABLE game_log(
        id          INTEGER PRIMARY KEY DEFAULT nextval('serial'),
        game_date   VARCHAR(255) NULL,
        opp         VARCHAR(255) NULL,
        score       VARCHAR(255) NULL,
        min         VARCHAR(255) NULL,
        fgm_fga     VARCHAR(255) NULL,
        fg_prct     VARCHAR(255) NULL,
        three_pm_pa VARCHAR(255) NULL,
        three_prct  VARCHAR(255) NULL,
        ftm_fta     VARCHAR(255) NULL,
        ft_prct     VARCHAR(255) NULL,
        reb         VARCHAR(255) NULL,
        ast         VARCHAR(255) NULL,
        blk         VARCHAR(255) NULL,
        stl         VARCHAR(255) NULL,
        pf          VARCHAR(255) NULL,
        turnovers   VARCHAR(255) NULL,
        pts         VARCHAR(255) NULL,
        updated_at  TIMESTAMP NOT NULL,
        created_at  TIMESTAMP NOT NULL
    )"

rescue PG::Error => e
    puts e.message

ensure
    conn.close if conn
    
end