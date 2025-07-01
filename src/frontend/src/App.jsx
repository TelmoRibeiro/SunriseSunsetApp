import { useState } from 'react'

function App() {
  const [location,  setLocation]  = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate,   setEndDate]   = useState("");
  const [records,   setRecords]   = useState([]);
  const [error,     setError]     = useState("");

  const handleSubmit = async (event) => {
    event.preventDefault();
    setError("");

    try {
      const response = await fetch(
        `http://localhost:4567/sun-data?location=${encodeURIComponent(location)}&start_date=${startDate}&end_date=${endDate}`
      );
      if (!response.ok) {
        const errorBody = await response.json();
        throw new Error(errorBody.error || "Request failed");
      }
      const data = await response.json();
      setRecords(data);
    } catch (err) {
      setError(err.message);
      setRecords([]);
    }
  };

  return (
    <div style={{ padding: "2rem", fontFamily: "Arial, sans-serif"}}>
      <h1>Sunrise & Sunset App</h1>

      <form onSubmit={handleSubmit} style={{ marginBottom: "1rem"}}>
        <input
          type='text'
          placeholder='placeholder'
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

      {error && <p style={{ color: "red"}}>{error}</p>}

      {records.length > 0 && (
        <table border="1" cellPadding="6">
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
      )}
    </div>
  );
}

export default App