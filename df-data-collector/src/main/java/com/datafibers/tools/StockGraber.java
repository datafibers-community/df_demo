package com.datafibers.tools;

import com.datafibers.conf.ConfigApp;
import org.codehaus.jackson.map.ObjectMapper;
import yahoofinance.Stock;
import yahoofinance.YahooFinance;
import java.io.IOException;
import java.nio.file.*;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;

import io.vertx.core.AbstractVerticle;
import io.vertx.core.file.FileSystem;
import yahoofinance.histquotes.HistoricalQuote;
import yahoofinance.histquotes.Interval;

import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;


/**
 * This is a tool to fetch stock data and dump it to a path in real time
 * This is used for DF demo purpose.
 */
public class StockGraber extends AbstractVerticle {

    public static String FILE_PATH;
    private ObjectMapper mapper;

    public static void main(String [] args) {

        ConfigApp.getAppConfig("sg.app.property");

        if(args.length != 0) {
            FILE_PATH = args[0];

        } else FILE_PATH = ConfigApp.getStockStageDir();

        System.out.println("INFO: Staging file at " + FILE_PATH);

        Runner.runExample(StockGraber.class);
    }

    public void start() {

        //HttpClient httpClient = vertx.createHttpClient(new HttpClientOptions());
        FileSystem fs = vertx.fileSystem();
        getJsonFileHist(ConfigApp.getStockList());
        getJsonFile(ConfigApp.getStockList());

    }

    public void getJsonFile(String[] symbols) {

        mapper = new org.codehaus.jackson.map.ObjectMapper();

        vertx.setPeriodic(ConfigApp.getPeriodic(), id -> {

            try {
                //create a new file end with .ignore
                String fileName = new SimpleDateFormat("'stock_'yyyyMMddhhmmss'.json.ignore'").format(new Date());
                String postFileName = fileName.replaceAll(".ignore",""); //This is used at post processing
                String jsonStr;
                Boolean printFull = ConfigApp.getPrintWay();

                Path stagFile = Paths.get(FILE_PATH, fileName);
                Path postStageFile = Paths.get(FILE_PATH, postFileName);

                if(!Files.exists(stagFile)) Files.createFile(stagFile);

                Map<String, Stock> stocks = YahooFinance.get(symbols); // single request
                for(String symbol : stocks.keySet()) {
                    Stock stock = stocks.get(symbol);
                    if(printFull) {
                        jsonStr = mapper.writeValueAsString(stock) + System.getProperty("line.separator");
                    } else jsonStr = getMinJsonInfo(stock, false) + System.getProperty("line.separator");
                    Files.write(stagFile, jsonStr.getBytes(), StandardOpenOption.APPEND);
                }

                //Rename by removing .ignore so that DF can process it
                Files.move(stagFile, postStageFile, REPLACE_EXISTING);

            } catch (IOException ioe) {
                ioe.printStackTrace();
            }

        });

    }

    public void getJsonFileHist(String[] symbols) {

        mapper = new org.codehaus.jackson.map.ObjectMapper();

        try {
            //create a new file end with .ignore
            String fileName = new SimpleDateFormat("'history_stock_'yyyyMMddhhmmss'.json.ignore'").format(new Date());
            String postFileName = fileName.replaceAll(".ignore",""); //This is used at post processing
            String jsonStr;
            Boolean printFull = ConfigApp.getPrintWay();

            Calendar from = Calendar.getInstance();
            Calendar to = Calendar.getInstance();
            from.add(Calendar.MONTH, -6); // from 6 months ago

            Path stagFile = Paths.get(FILE_PATH, fileName);
            Path postStageFile = Paths.get(FILE_PATH, postFileName);

            if(!Files.exists(stagFile)) Files.createFile(stagFile);

            Map<String, Stock> stocks = YahooFinance.get(symbols); // single request

            for(String symbol : stocks.keySet()) {
                Stock stock = stocks.get(symbol);
                List<HistoricalQuote> histQuotes = stock.getHistory(from, to, Interval.DAILY);
                for (HistoricalQuote aQuote : histQuotes) {
                    jsonStr = getMinJsonInfo(aQuote) + System.getProperty("line.separator");
                    Files.write(stagFile, jsonStr.getBytes(), StandardOpenOption.APPEND);
                }
            }
            //Rename by removing .ignore so that DF can process it
            Files.move(stagFile, postStageFile, REPLACE_EXISTING);

        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

    }

    public String getMinJsonInfo(Stock stock, Boolean refresh) {

        try {
            DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
            String jsonStr = "{\"time\":\"" + df.format(new Date()) +
                             "\",\"symbol\":\"" + stock.getSymbol() +
                             "\",\"name\":\"" + stock.getName() +
                             "\",\"exchange\":\""  + stock.getStockExchange() +
                             "\",\"open_price\":" + stock.getQuote(refresh).getOpen() +
                             ",\"ask_price\":" + stock.getQuote(refresh).getAsk() +
                             ",\"ask_size\":" + stock.getQuote(refresh).getAskSize() +
                             ",\"bid_price\":" + stock.getQuote(refresh).getBid() +
                             ",\"bid_size\":" + stock.getQuote(refresh).getBidSize() +
                             ",\"price\":" +  stock.getQuote(refresh).getPrice() +
                             "}";
            return jsonStr;

        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return null;


    }

    /**
     * This is manily for history data printout
     * @param stockHist
     * @return
     */
    public String getMinJsonInfo(HistoricalQuote stockHist) {

        DateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        String jsonStr = "{\"time\":\"" + df.format(stockHist.getDate().getTime()) +
                "\",\"symbol\":\"" + stockHist.getSymbol() +
                "\",\"name\":\"" + stockHist.getSymbol() +
                "\",\"exchange\":\""  + "NULL" +
                "\",\"open_price\":" + stockHist.getOpen() +
                ",\"ask_price\":" + stockHist.getAdjClose() +
                ",\"ask_size\":" + stockHist.getVolume() +
                ",\"bid_price\":" +stockHist.getHigh() +
                ",\"bid_size\":" + stockHist.getVolume() +
                ",\"price\":" +  stockHist.getClose() +
                "}";

        return jsonStr;

    }

}
