
import axios from 'axios'
import React, { useEffect, useState } from "react";



export default function BetterSchoolBilling () {
  const [users, setUsers]= useState([])
  const [form,setForm] = useState({name:"",email:""})

   useEffect(() => {
    axios.get(`/api/users`).then((res) => {
      setUsers(res.data);
    });
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    axios.post(`/api/users`, form).then((res) => {
      setUsers((prev) => [...prev, res.data]);
      setForm({ name: "", email: "" });
    });
  };

  return (
    <div style={{ padding: "2rem", fontFamily: "Arial, sans-serif" }}>
      <h1>BetterSchoolBilling</h1>
      <p>
        BetterSchoolBilling is a user-friendly offline fee and billing software
        designed to simplify school financial operations. It offers a seamless
        experience for managing student payments, generating invoices, and
        tracking transactions — all without needing an internet connection.
      </p>
      <h2>User List</h2>

      <form onSubmit={handleSubmit}>
        <input
          placeholder="Name"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
        />
        <input
          placeholder="Email"
          value={form.email}
          onChange={(e) => setForm({ ...form, email: e.target.value })}
        />
        <button type="submit">Add User</button>
      </form>

      <ul>
        {users.map((user, idx) => (
          <li key={idx}>
            {user.name} - {user.email}
          </li>
        ))}
      </ul>
    </div>
  );
};


