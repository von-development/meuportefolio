'use client';

import { User } from "@/lib/api";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { CalendarIcon, CreditCardIcon, PencilIcon, UserIcon } from "lucide-react";
import { formatDate } from "@/lib/utils";

interface UserProfileHeaderProps {
  user: User;
  onEdit?: () => void;
}

export function UserProfileHeader({ user, onEdit }: UserProfileHeaderProps) {
  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map(part => part[0])
      .join('')
      .toUpperCase();
  };

  return (
    <div className="relative w-full bg-gradient-to-r from-blue-600 via-blue-700 to-blue-800">
      {/* Background Pattern */}
      <div className="absolute inset-0 bg-grid-white/[0.05] bg-[size:20px_20px]" />
      
      {/* Gradient Overlay */}
      <div className="absolute inset-0 bg-gradient-to-t from-background/80 to-background/20" />
      
      <div className="relative container mx-auto px-4 py-16">
        <div className="flex flex-col md:flex-row items-center gap-6">
          <Avatar className="h-24 w-24 border-4 border-background shadow-xl">
            <AvatarImage src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${user.user_id}`} />
            <AvatarFallback className="text-2xl">{getInitials(user.name)}</AvatarFallback>
          </Avatar>
          
          <div className="flex-1 text-center md:text-left space-y-2">
            <div className="flex flex-col md:flex-row items-center gap-3">
              <h1 className="text-3xl font-bold text-white">{user.name}</h1>
              <Badge variant={user.user_type === 'Premium' ? "default" : "secondary"} className={user.user_type === 'Premium' ? 'bg-amber-500 hover:bg-amber-600' : ''}>
                {user.user_type}
              </Badge>
            </div>
            
            <div className="flex flex-col md:flex-row items-center gap-4 text-zinc-200">
              <p className="flex items-center gap-2">
                <span className="text-zinc-400">Email:</span>
                {user.email}
              </p>
              <span className="hidden md:inline text-zinc-400">•</span>
              <p className="flex items-center gap-2">
                <span className="text-zinc-400">País:</span>
                {user.country_of_residence}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 