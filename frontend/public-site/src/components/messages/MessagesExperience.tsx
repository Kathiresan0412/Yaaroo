"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, Camera, Flag, Image as ImageIcon, Mic, Send, Smile, Trash2, X } from "lucide-react";
import { io, type Socket } from "socket.io-client";
import { useAuth } from "../auth/AuthProvider";
import { readOfflineCache, trackClientEvent, writeOfflineCache } from "../../lib/offline-cache";

type ChatMessage = {
  id: string;
  matchId: string;
  senderId: string;
  type: "text" | "photo" | "gif" | "voice" | "image" | "system";
  content: string | null;
  mediaUrl: string | null;
  durationSeconds: number | null;
  reactions: { userId: string; emoji: string }[];
  isMine: boolean;
  isRead: boolean;
  readAt: string | null;
  isDeleted: boolean;
  createdAt: string;
  pending?: boolean;
};

type MessagesPayload = {
  success: boolean;
  messages: ChatMessage[];
  nextCursor: string | null;
  message?: string;
};

const socketUrl = process.env.NEXT_PUBLIC_YAARO0_SOCKET_URL || "http://127.0.0.1:8000";
const gifChoices = [
  "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcnV6dW1zZHY3dW5kdzYzbjdiaWl1MHN4bGlna3F0d2U5M2drYm90NSZlcD12MV9naWZzX3NlYXJjaCZjdD1n/3oriO0OEd9QIDdllqo/giphy.gif",
  "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExaDd0N2s0MmI5YnUydnVvOXM0cmFucnF3bmxwbm93M2kwY3N3bTliZCZlcD12MV9naWZzX3NlYXJjaCZjdD1n/l0MYt5jPR6QX5pnqM/giphy.gif",
  "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNHRqeTQ1a2Y3ZXl4d21ybXlpc3ZtN2xyYzZzN2VucXRpZWI3dThiaSZlcD12MV9naWZzX3NlYXJjaCZjdD1n/26BRv0ThflsHCqDrG/giphy.gif",
];
const reactionChoices = ["❤️", "😂", "🔥", "👏", "✨"];

async function fileToDataUrl(file: File) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ""));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

function mergeMessages(existing: ChatMessage[], incoming: ChatMessage[]) {
  const map = new Map<string, ChatMessage>();

  [...incoming, ...existing].forEach((message) => map.set(message.id, { ...map.get(message.id), ...message }));

  return Array.from(map.values()).sort(
    (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
  );
}

export function MessagesExperience({ matchId }: { matchId: string }) {
  const router = useRouter();
  const { accessToken, authFetch, user } = useAuth();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [draft, setDraft] = useState("");
  const [notice, setNotice] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [isOnline, setIsOnline] = useState(false);
  const [matchName, setMatchName] = useState("Match chat");
  const [showGifs, setShowGifs] = useState(false);
  const [selectedMessageId, setSelectedMessageId] = useState<string | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const socketRef = useRef<Socket | null>(null);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const scrollerRef = useRef<HTMLDivElement | null>(null);
  const matchedUserIdRef = useRef("");

  const selectedMessage = useMemo(
    () => messages.find((message) => message.id === selectedMessageId) || null,
    [messages, selectedMessageId],
  );
  const lastMineRead = [...messages].reverse().find((message) => message.isMine && message.isRead);

  const loadMessages = useCallback(
    async (cursor?: string | null) => {
      const params = new URLSearchParams({ limit: "30" });

      if (cursor) {
        params.set("cursor", cursor);
      }

      const response = await authFetch(`/api/messages/${matchId}?${params.toString()}`);
      const payload = (await response.json()) as MessagesPayload;

      if (!response.ok) {
        throw new Error(payload.message || "Unable to load messages.");
      }

      setMessages((current) => mergeMessages(current, payload.messages));
      setNextCursor(payload.nextCursor);
      if (!cursor) {
        writeOfflineCache(`messages:${matchId}`, {
          messages: payload.messages,
          nextCursor: payload.nextCursor,
        });
      }
    },
    [authFetch, matchId],
  );

  useEffect(() => {
    loadMessages()
      .catch((error) => {
        const cached = readOfflineCache<{ messages: ChatMessage[]; nextCursor: string | null }>(`messages:${matchId}`);

        if (cached) {
          setMessages(cached.messages);
          setNextCursor(cached.nextCursor);
          setNotice("Showing saved messages while Yaaro0 reconnects.");
          return;
        }

        setNotice(error instanceof Error ? error.message : "Messages are unavailable.");
      })
      .finally(() => setIsLoading(false));
  }, [loadMessages]);

  useEffect(() => {
    authFetch("/api/matches")
      .then((response) => response.json())
      .then((payload: { matches?: { id: string; user: { id: string; displayName: string } }[] }) => {
        const match = payload.matches?.find((item) => item.id === matchId);

        if (match) {
          matchedUserIdRef.current = match.user.id;
          setMatchName(match.user.displayName);
        }
      })
      .catch(() => undefined);
  }, [authFetch, matchId]);

  useEffect(() => {
    if (!accessToken) {
      return;
    }

    const socket = io(socketUrl, { auth: { token: accessToken }, transports: ["websocket", "polling"] });
    socketRef.current = socket;

    socket.on("connect", () =>
      socket.emit(
        "join_match",
        { matchId },
        (ack: { success?: boolean; otherUserId?: string; isOnline?: boolean }) => {
          if (ack.success && ack.otherUserId) {
            matchedUserIdRef.current = ack.otherUserId;
            setIsOnline(Boolean(ack.isOnline));
          }
        },
      ),
    );
    socket.on("new_message", (message: ChatMessage) => {
      if (message.matchId !== matchId) {
        return;
      }

      setMessages((current) => mergeMessages(current, [{ ...message, isMine: message.senderId === user?.id }]));
      socket.emit("mark_read", { matchId, messageId: message.id });
    });
    socket.on("message_read", ({ matchId: eventMatchId, readAt }: { matchId: string; readAt: string }) => {
      if (eventMatchId !== matchId) {
        return;
      }

      setMessages((current) =>
        current.map((message) => (message.isMine ? { ...message, isRead: true, readAt } : message)),
      );
    });
    socket.on("message_reaction", ({ message }: { message: ChatMessage }) => {
      setMessages((current) => current.map((item) => (item.id === message.id ? { ...item, ...message } : item)));
    });
    socket.on("presence_update", ({ userId: eventUserId, isOnline: online }: { userId: string; isOnline: boolean }) => {
      if (eventUserId === matchedUserIdRef.current) {
        setIsOnline(online);
      }
    });
    socket.on("connect_error", () => setNotice("Live chat is reconnecting."));

    return () => {
      socket.emit("leave_match", { matchId });
      socket.disconnect();
      socketRef.current = null;
    };
  }, [accessToken, matchId, user?.id]);

  useEffect(() => {
    scrollerRef.current?.scrollTo({ top: scrollerRef.current.scrollHeight });
  }, [messages.length]);

  async function loadMore() {
    if (!nextCursor || isLoadingMore) {
      return;
    }

    setIsLoadingMore(true);
    await loadMessages(nextCursor)
      .catch((error) => setNotice(error instanceof Error ? error.message : "Unable to load older messages."))
      .finally(() => setIsLoadingMore(false));
  }

  async function sendPayload(payload: Record<string, unknown>) {
    const response = await authFetch(`/api/messages/${matchId}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = (await response.json()) as { success: boolean; message?: ChatMessage | string };

    if (!response.ok || typeof body.message === "string") {
      throw new Error(typeof body.message === "string" ? body.message : "Unable to send message.");
    }

    setMessages((current) => mergeMessages(current, [body.message as ChatMessage]));
    trackClientEvent("message_sent", { matchId, type: payload.type || "text" });
  }

  async function sendText() {
    const content = draft.trim();

    if (!content) {
      return;
    }

    setDraft("");
    socketRef.current?.emit("send_message", { matchId, content, type: "text" }, (ack: { success?: boolean; message?: string }) => {
      if (!ack?.success) {
        setNotice(ack?.message || "Unable to send message.");
      }
    });
  }

  async function sendPhoto(file: File) {
    try {
      await sendPayload({ type: "photo", mediaUrl: await fileToDataUrl(file) });
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "Unable to send photo.");
    }
  }

  async function sendGif(url: string) {
    setShowGifs(false);
    try {
      await sendPayload({ type: "gif", gifUrl: url });
    } catch (error) {
      setNotice(error instanceof Error ? error.message : "Unable to send GIF.");
    }
  }

  async function toggleRecording() {
    if (isRecording) {
      recorderRef.current?.stop();
      setIsRecording(false);
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream);
      chunksRef.current = [];
      recorderRef.current = recorder;
      recorder.ondataavailable = (event) => chunksRef.current.push(event.data);
      recorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const blob = new Blob(chunksRef.current, { type: "audio/webm" });
        const formData = new FormData();
        formData.append("voice", blob, "voice.webm");
        const response = await authFetch(`/api/messages/${matchId}/voice`, { method: "POST", body: formData });
        const payload = (await response.json()) as { success: boolean; message?: ChatMessage | string };

        if (!response.ok || typeof payload.message === "string") {
          setNotice(typeof payload.message === "string" ? payload.message : "Unable to send voice note.");
          return;
        }

        setMessages((current) => mergeMessages(current, [payload.message as ChatMessage]));
      };
      recorder.start();
      setIsRecording(true);
    } catch {
      setNotice("Microphone access is needed for voice notes.");
    }
  }

  async function react(messageId: string, emoji: string) {
    socketRef.current?.emit("react_message", { messageId, emoji });
    setSelectedMessageId(null);
  }

  async function deleteMessage(messageId: string) {
    const response = await authFetch(`/api/message-actions/${messageId}`, { method: "DELETE" });
    const payload = (await response.json()) as { success: boolean; message?: ChatMessage };

    if (response.ok && payload.message) {
      setMessages((current) => current.map((message) => (message.id === messageId ? payload.message! : message)));
    }

    setSelectedMessageId(null);
  }

  async function reportMessage(messageId: string) {
    await authFetch(`/api/message-actions/${messageId}?action=report`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reason: "chat_report" }),
    });
    setNotice("Message reported.");
    setSelectedMessageId(null);
  }

  return (
    <main className="chat-shell">
      <header className="chat-header">
        <button aria-label="Back to matches" onClick={() => router.push("/app/matches")}>
          <ArrowLeft size={20} />
        </button>
        <div>
          <span className={isOnline ? "chat-presence online" : "chat-presence"} />
          <strong>{matchName}</strong>
          <small>{isOnline ? "Online now" : "Messages sync when they reconnect"}</small>
        </div>
      </header>

      {notice ? (
        <p className="chat-notice">
          {notice}
          <button aria-label="Dismiss" onClick={() => setNotice("")}>
            <X size={14} />
          </button>
        </p>
      ) : null}

      <section
        ref={scrollerRef}
        className="chat-thread"
        onScroll={(event) => {
          if (event.currentTarget.scrollTop < 24) {
            void loadMore();
          }
        }}
      >
        {nextCursor ? (
          <button className="chat-load-more" disabled={isLoadingMore} onClick={loadMore}>
            {isLoadingMore ? "Loading..." : "Older messages"}
          </button>
        ) : null}
        {isLoading ? (
          <div className="chat-skeleton" aria-label="Loading messages">
            <span />
            <span />
            <span />
          </div>
        ) : null}
        {!isLoading && messages.length === 0 ? <p className="chat-empty">Say hello to start the chat.</p> : null}
        {messages.map((message) => (
          <article
            key={message.id}
            className={message.isMine ? "chat-bubble mine" : "chat-bubble"}
            onDoubleClick={() => setSelectedMessageId(message.id)}
          >
            {message.isDeleted ? (
              <em>Message deleted</em>
            ) : message.type === "photo" || message.type === "image" || message.type === "gif" ? (
              <img src={message.mediaUrl || ""} alt={message.type === "gif" ? "GIF message" : "Photo message"} />
            ) : message.type === "voice" ? (
              <audio controls src={message.mediaUrl || ""} />
            ) : (
              <p>{message.content}</p>
            )}
            <div className="chat-meta">
              <time>{new Date(message.createdAt).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}</time>
              <button aria-label="React" onClick={() => setSelectedMessageId(message.id)}>
                <Smile size={14} />
              </button>
            </div>
            {message.reactions.length ? (
              <div className="chat-reactions">{message.reactions.map((reaction) => reaction.emoji).join(" ")}</div>
            ) : null}
          </article>
        ))}
        {lastMineRead ? <span className="chat-seen">Seen {new Date(lastMineRead.readAt || "").toLocaleTimeString()}</span> : null}
      </section>

      {selectedMessage ? (
        <div className="chat-action-bar">
          {reactionChoices.map((emoji) => (
            <button key={emoji} onClick={() => react(selectedMessage.id, emoji)}>
              {emoji}
            </button>
          ))}
          <button aria-label="Delete" onClick={() => deleteMessage(selectedMessage.id)}>
            <Trash2 size={18} />
          </button>
          <button aria-label="Report" onClick={() => reportMessage(selectedMessage.id)}>
            <Flag size={18} />
          </button>
        </div>
      ) : null}

      {showGifs ? (
        <div className="gif-picker">
          {gifChoices.map((url) => (
            <button key={url} onClick={() => sendGif(url)}>
              <img src={url} alt="GIF option" />
            </button>
          ))}
        </div>
      ) : null}

      <footer className="chat-composer">
        <label aria-label="Send photo">
          <Camera size={20} />
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            onChange={(event) => {
              const file = event.target.files?.[0];
              if (file) void sendPhoto(file);
              event.currentTarget.value = "";
            }}
          />
        </label>
        <button aria-label="Choose GIF" onClick={() => setShowGifs((value) => !value)}>
          <ImageIcon size={20} />
        </button>
        <button className={isRecording ? "recording" : ""} aria-label="Record voice" onClick={toggleRecording}>
          <Mic size={20} />
        </button>
        <input
          value={draft}
          onChange={(event) => setDraft(event.target.value)}
          onKeyDown={(event) => {
            if (event.key === "Enter") void sendText();
          }}
          placeholder="Message..."
        />
        <button aria-label="Send" onClick={sendText}>
          <Send size={20} />
        </button>
      </footer>
    </main>
  );
}
