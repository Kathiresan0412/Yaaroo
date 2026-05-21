import { MessagesExperience } from "../../../../components/messages/MessagesExperience";

type PageProps = {
  params: Promise<{ matchId: string }>;
};

export default async function AppMessagesPage({ params }: PageProps) {
  const { matchId } = await params;

  return <MessagesExperience matchId={matchId} />;
}
