/**
 * EmotiGuard Chart Manager
 * Manages high-performance Chart.js instances for real-time telemetry streaming
 * and multi-parameter session analytics.
 */

import { APP_CONFIG } from '../config.js';

export class ChartManager {
  constructor() {
    this.liveChart = null;
    this.historyChart = null;
    this.maxDataPoints = APP_CONFIG.STREAMING.MAX_LIVE_POINTS;
  }

  initLiveChart(canvasId) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return null;
    const ctx = canvas.getContext('2d');

    // Gradient fills
    const hrGrad = ctx.createLinearGradient(0, 0, 0, 300);
    hrGrad.addColorStop(0, 'rgba(244, 63, 94, 0.28)');
    hrGrad.addColorStop(1, 'rgba(244, 63, 94, 0.0)');

    const gsrGrad = ctx.createLinearGradient(0, 0, 0, 300);
    gsrGrad.addColorStop(0, 'rgba(6, 182, 212, 0.28)');
    gsrGrad.addColorStop(1, 'rgba(6, 182, 212, 0.0)');

    this.liveChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: [],
        datasets: [
          {
            label: 'Heart Rate (BPM)',
            data: [],
            borderColor: '#F43F5E',
            backgroundColor: hrGrad,
            borderWidth: 2.2,
            tension: 0.35,
            fill: true,
            yAxisID: 'yCardiac',
            pointRadius: 0,
            pointHoverRadius: 4
          },
          {
            label: 'HRV RMSSD (ms)',
            data: [],
            borderColor: '#A855F7',
            backgroundColor: 'transparent',
            borderWidth: 2,
            borderDash: [4, 4],
            tension: 0.35,
            fill: false,
            yAxisID: 'yCardiac',
            pointRadius: 0,
            pointHoverRadius: 4
          },
          {
            label: 'Skin Conductance (µS)',
            data: [],
            borderColor: '#06B6D4',
            backgroundColor: gsrGrad,
            borderWidth: 2.2,
            tension: 0.35,
            fill: true,
            yAxisID: 'yGSR',
            pointRadius: 0,
            pointHoverRadius: 4
          },
          {
            label: 'SpO2 (%)',
            data: [],
            borderColor: '#10B981',
            backgroundColor: 'transparent',
            borderWidth: 1.8,
            tension: 0.2,
            fill: false,
            yAxisID: 'yCardiac',
            pointRadius: 0,
            pointHoverRadius: 4,
            hidden: true // Optional toggle
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 350,
          easing: 'easeOutQuad'
        },
        interaction: {
          mode: 'index',
          intersect: false
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            labels: {
              color: '#94A3B8',
              usePointStyle: true,
              boxWidth: 8,
              font: { family: 'ui-sans-serif, system-ui, sans-serif', size: 12 }
            }
          },
          tooltip: {
            backgroundColor: 'rgba(15, 23, 42, 0.95)',
            borderColor: 'rgba(56, 189, 248, 0.3)',
            borderWidth: 1,
            titleColor: '#F8FAFC',
            bodyColor: '#CBD5E1',
            padding: 10,
            boxPadding: 4
          }
        },
        scales: {
          x: {
            grid: {
              color: 'rgba(51, 65, 85, 0.25)',
              drawBorder: false
            },
            ticks: {
              color: '#64748B',
              maxTicksLimit: 8,
              font: { size: 10 }
            }
          },
          yCardiac: {
            type: 'linear',
            position: 'left',
            min: 30,
            max: 180,
            grid: {
              color: 'rgba(51, 65, 85, 0.25)',
              drawBorder: false
            },
            ticks: {
              color: '#F43F5E',
              font: { size: 11 },
              callback: (val) => `${val}`
            },
            title: {
              display: true,
              text: 'Cardiac (BPM / ms)',
              color: '#94A3B8',
              font: { size: 10 }
            }
          },
          yGSR: {
            type: 'linear',
            position: 'right',
            min: 0,
            max: 20,
            grid: {
              drawOnChartArea: false,
              drawBorder: false
            },
            ticks: {
              color: '#06B6D4',
              font: { size: 11 },
              callback: (val) => `${val} µS`
            },
            title: {
              display: true,
              text: 'EDA / GSR (µS)',
              color: '#06B6D4',
              font: { size: 10 }
            }
          }
        }
      }
    });

    return this.liveChart;
  }

  addLiveSample(sample) {
    if (!this.liveChart) return;

    const labels = this.liveChart.data.labels;
    const hrData = this.liveChart.data.datasets[0].data;
    const hrvData = this.liveChart.data.datasets[1].data;
    const gsrData = this.liveChart.data.datasets[2].data;
    const spo2Data = this.liveChart.data.datasets[3].data;

    // Time label (HH:MM:SS)
    const label = sample.timestampLocal || new Date(sample.timestamp).toLocaleTimeString();

    labels.push(label);
    hrData.push(sample.hr);
    hrvData.push(sample.hrv);
    gsrData.push(sample.gsr);
    spo2Data.push(sample.spo2);

    // Limit window size
    if (labels.length > this.maxDataPoints) {
      labels.shift();
      hrData.shift();
      hrvData.shift();
      gsrData.shift();
      spo2Data.shift();
    }

    this.liveChart.update('none'); // Update smoothly without full animation hitch
  }

  resetLiveChart() {
    if (!this.liveChart) return;
    this.liveChart.data.labels = [];
    this.liveChart.data.datasets.forEach(ds => ds.data = []);
    this.liveChart.update();
  }

  renderHistoricalSession(canvasId, session, metricKey = 'all') {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    if (this.historyChart) {
      this.historyChart.destroy();
    }

    if (!session || !session.samples || session.samples.length === 0) {
      return;
    }

    const labels = session.samples.map(s => s.timestampLocal || new Date(s.timestamp).toLocaleTimeString());
    let datasets = [];

    if (metricKey === 'all' || metricKey === 'hr') {
      datasets.push({
        label: 'Heart Rate (BPM)',
        data: session.samples.map(s => s.hr),
        borderColor: '#F43F5E',
        backgroundColor: 'rgba(244, 63, 94, 0.1)',
        fill: true,
        tension: 0.3,
        pointRadius: 1
      });
    }

    if (metricKey === 'all' || metricKey === 'hrv') {
      datasets.push({
        label: 'HRV RMSSD (ms)',
        data: session.samples.map(s => s.hrv),
        borderColor: '#A855F7',
        backgroundColor: 'rgba(168, 85, 247, 0.1)',
        fill: false,
        tension: 0.3,
        pointRadius: 1
      });
    }

    if (metricKey === 'all' || metricKey === 'gsr') {
      datasets.push({
        label: 'Skin Conductance (µS)',
        data: session.samples.map(s => s.gsr),
        borderColor: '#06B6D4',
        backgroundColor: 'rgba(6, 182, 212, 0.15)',
        fill: true,
        tension: 0.3,
        pointRadius: 1
      });
    }

    if (metricKey === 'all' || metricKey === 'spo2') {
      datasets.push({
        label: 'SpO2 (%)',
        data: session.samples.map(s => s.spo2),
        borderColor: '#10B981',
        backgroundColor: 'transparent',
        fill: false,
        tension: 0.2,
        pointRadius: 1
      });
    }

    this.historyChart = new Chart(ctx, {
      type: 'line',
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          legend: {
            display: true,
            labels: { color: '#94A3B8', boxWidth: 10 }
          },
          tooltip: {
            backgroundColor: 'rgba(15, 23, 42, 0.95)',
            borderColor: 'rgba(56, 189, 248, 0.3)',
            borderWidth: 1
          }
        },
        scales: {
          x: {
            grid: { color: 'rgba(51, 65, 85, 0.2)' },
            ticks: { color: '#64748B', maxTicksLimit: 12 }
          },
          y: {
            grid: { color: 'rgba(51, 65, 85, 0.2)' },
            ticks: { color: '#94A3B8' }
          }
        }
      }
    });
  }
}
