import { useState } from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';


function App() {
  const [location,  setLocation]  = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate,   setEndDate]   = useState("");
  const [records,   setRecords]   = useState([]);
  const [error,     setError]     = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setIsLoading(true);
    try {
      const parameters = new URLSearchParams({ location: location, start_date: startDate, end_date: endDate });
      const response = await fetch(`http://localhost:4567/sun-data?${parameters}`);
      if (!response.ok) {
        const errorMessage = await response.json();
        throw new Error(errorMessage.error || 'Could not resolve the error message' + response.status);
      }
      const data = await response.json();
      setRecords(data);
    } catch (err) {
      setError(err.message);
      setRecords([]);
    } finally {
      setIsLoading(false);
    }
  };

  const processData = records.map(record => {
    const toSeconds = timeString => {
      const [time, period]               = timeString.trim().split(' ');
      const [rawHours, minutes, seconds] = time.split(':').map(Number);
      let hours = rawHours % 12;
      if (period.toUpperCase() == 'PM') hours += 12;
      return hours * 3600 + minutes * 60 + seconds;
    };

    return {
      latitude:    record.latitude,
      longitude:   record.longitude,
      location:    record.location,
      date:        record.date,
      sunrise:     toSeconds(record.sunrise),
      sunset:      toSeconds(record.sunset),
      golden_hour: toSeconds(record.golden_hour),
    };
  });

  const formatTime = (value) => {
    const hours   = Math.floor(value / 3600).toString().padStart(2, '0');
    const minutes = Math.floor(value % 3600 / 60).toString().padStart(2, '0');
    const seconds = (value % 60).toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }

  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial' }}>
      <h1>Sunrise & Sunset App</h1>

      <form onSubmit={handleSubmit} style={{ marginBottom: '1rem'}}>
        <input
          type='text'
          placeholder='location (e.g., Lisbon)'
          value={location}
          onChange={(e) => setLocation(e.target.value)}
          required
        />
        <input
          type='date'
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
          required
        />
        <input
          type='date'
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          required
        />
        <button type='submit'>Get Data</button>
      </form>

      {isLoading && <p style={{ color: 'white' }}>'Loading...'</p>}

      {error && <p style={{ color: 'red' }}>{error}</p>}

      {records.length > 0 && (
        <>
          <h2>Table</h2>
          <table border='2' cellPadding='2' width='50%'>
            <thead>
              <tr>
                <th>Location</th>
                <th>Date</th>
                <th>Sunrise</th>
                <th>Sunset</th>
                <th>Golden Hour</th>
              </tr>
            </thead>
            <tbody>
              {records.map((record, index) => (
                <tr key={index}>
                  <td>{record.location}</td>
                  <td>{record.date}</td>
                  <td>{record.sunrise}</td>
                  <td>{record.sunset}</td>
                  <td>{record.golden_hour}</td>
                </tr>
              ))}
            </tbody>
          </table>
        
          <h2> Chart</h2>
          <div style={{overflow: 'auto', overflowY: 'hidden' }}>
            <div style={{ width: `${records.length * 80}px`, minWidth: `1000px` }}>
              <ResponsiveContainer width='100%' height={400}>
                <LineChart
                  data={processData}
                  margin={{ top: 10, right: 60, left: 60, bottom: 10 }}  
                >
                  <CartesianGrid stroke='#ccc' />
                  <XAxis dataKey='date' interval={0} /> // without interval the second to last line disappears
                  <YAxis
                    domain={[0, 86399]}
                    ticks={[0, 21600, 43200, 64800, 86399]}
                    tickFormatter={formatTime}
                  />
                  <Tooltip
                    formatter={formatTime}
                  />
                  <Legend />
                  <Line type='monotone' dataKey='sunrise'     stroke='#1E90FF' name='Sunrise' />
                  <Line type='monotone' dataKey='sunset'      stroke='#FF4500' name='Sunset'  />
                  <Line type='monotone' dataKey='golden_hour' stroke='#FFD700' name='Golden Hour' />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default App