import { api } from "@/lib/api";
import { UsersClient } from "@/components/users/users-client";

export default async function UsersPage() {
  const users = await api.getUsers();
  return <UsersClient users={users} />;
} 