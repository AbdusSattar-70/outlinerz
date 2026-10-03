import { AuthForm } from '@/modules/organizations/auth-form';
export default async function SignInPage({searchParams}:{searchParams:Promise<{error?:string}>}){
 const query=await searchParams;
 return <AuthForm confirmationError={query.error==='confirmation'}/>;
}
