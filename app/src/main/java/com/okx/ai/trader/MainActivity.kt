package com.okx.ai.trader

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.okx.ai.trader.data.MarketRepository
import com.okx.ai.trader.indicators.IndicatorSummary
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    OkxAnalyzerScreen()
                }
            }
        }
    }
}

@Composable
fun OkxAnalyzerScreen() {
    var symbol by remember { mutableStateOf("BTC-USDT-SWAP") }
    var timeframe by remember { mutableStateOf("1H") }
    var isLoading by remember { mutableStateOf(false) }
    var indicatorSummary by remember { mutableStateOf<IndicatorSummary?>(null) }
    var aiAnalysis by remember { mutableStateOf("") }
    var errorMsg by remember { mutableStateOf("") }

    val repo = remember { MarketRepository() }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.Top,
        horizontalAlignment = Alignment.Start
    ) {
        Text("OKX AI Trading Assistant", style = MaterialTheme.typography.headlineSmall)
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            OutlinedTextField(value = symbol, onValueChange = { symbol = it }, label = { Text("Symbol") })
            OutlinedTextField(value = timeframe, onValueChange = { timeframe = it }, label = { Text("Timeframe (e.g., 1m, 5m, 1H, 1D)") })
        }
        Spacer(Modifier.height(12.dp))
        Button(enabled = !isLoading, onClick = {
            isLoading = true
            errorMsg = ""
            aiAnalysis = ""
            indicatorSummary = null
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val data = repo.fetchKlines(symbol = symbol, bar = timeframe, limit = 500)
                    val summary = repo.computeIndicators(data)
                    val analysis = repo.generateAiAnalysis(symbol, timeframe, summary)
                    indicatorSummary = summary
                    aiAnalysis = analysis
                } catch (t: Throwable) {
                    errorMsg = t.message ?: t.toString()
                } finally {
                    isLoading = false
                }
            }
        }) {
            Text("Analyze")
        }
        Spacer(Modifier.height(16.dp))
        if (isLoading) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CircularProgressIndicator()
                Spacer(Modifier.height(8.dp))
            }
        }
        if (errorMsg.isNotBlank()) {
            Text("Error: $errorMsg", color = MaterialTheme.colorScheme.error)
        }
        indicatorSummary?.let { s ->
            Spacer(Modifier.height(8.dp))
            Text("Indicators:", style = MaterialTheme.typography.titleMedium)
            Text(s.toPrettyString())
        }
        if (aiAnalysis.isNotBlank()) {
            Spacer(Modifier.height(8.dp))
            Text("AI Analysis:", style = MaterialTheme.typography.titleMedium)
            Text(aiAnalysis)
        }
        Spacer(Modifier.height(24.dp))
        Text("Disclaimer: This is not financial advice. Trading involves risk.", style = MaterialTheme.typography.bodySmall)
    }
}