import { Router, Request, Response } from "express";
import { generateId, validateEmail, formatTimestamp } from "../utils/helpers";

const router = Router();

interface User {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

// In-memory store (would use a real DB in production)
const users: User[] = [
  {
    id: "usr_001",
    name: "Alice Johnson",
    email: "alice@example.com",
    createdAt: formatTimestamp(new Date("2024-01-15")),
  },
  {
    id: "usr_002",
    name: "Bob Smith",
    email: "bob@example.com",
    createdAt: formatTimestamp(new Date("2024-02-20")),
  },
];

// GET /api/users
router.get("/", (_req: Request, res: Response) => {
  res.json({ users, count: users.length });
});

// GET /api/users/:id
router.get("/:id", (req: Request, res: Response) => {
  const user = users.find((u) => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }
  res.json({ user });
});

// POST /api/users
router.post("/", (req: Request, res: Response) => {
  const { name, email } = req.body;

  if (!name || !email) {
    return res.status(400).json({ error: "Name and email are required" });
  }

  if (!validateEmail(email)) {
    return res.status(400).json({ error: "Invalid email format" });
  }

  // Check for duplicate email
  if (users.some((u) => u.email === email)) {
    return res.status(409).json({ error: "Email already exists" });
  }

  const newUser: User = {
    id: generateId("usr"),
    name,
    email,
    createdAt: formatTimestamp(new Date()),
  };

  users.push(newUser);
  res.status(201).json({ user: newUser });
});

// DELETE /api/users/:id
router.delete("/:id", (req: Request, res: Response) => {
  const index = users.findIndex((u) => u.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: "User not found" });
  }
  const deleted = users.splice(index, 1)[0];
  res.json({ message: "User deleted", user: deleted });
});

export { router as userRouter };
